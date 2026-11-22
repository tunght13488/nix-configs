#!/usr/bin/env bash
# pi-box - run the Pi coding agent in a per-project nono capability sandbox.
#
# Installed by home-manager/pi-sandbox.nix. The static policy lives in the
# deployed base profile ~/.config/nono/profiles/pi-box.json; the project's
# untracked pi-box.profile.json extends it by name. This wrapper generates only
# the per-run overlay - the parts that cannot be static: the workspace grant,
# a worktree's git common directory, the repository root AGENTS.md, the herdr
# socket, and the GitHub token route - and runs
# `nono run --profile <project|pi-box> --extends pi-box-overlay-<project>`.
#
# Never granted (by the base profile): ~/.aws, ~/.ssh, the 1Password socket,
# ~/.cache, /tmp, or any other host path.

set -euo pipefail

SANDBOX_DIR="${PI_BOX_SANDBOX_DIR:-$HOME/.pi/sandbox}"
TEMPLATE_DIR="$SANDBOX_DIR/templates"
GH_TOKEN_FILE="$SANDBOX_DIR/gh-token"
RUNTIME_DIR="$SANDBOX_DIR/runtime"
TMP_DIR="$SANDBOX_DIR/tmp"
# The deployed base profile; nono resolves it by name from
# ~/.config/nono/profiles/.
BASE_PROFILE="pi-box"
# Prefer the nixpkgs nono; fall back to PATH for a hand-installed binary.
NONO="${PI_BOX_NONO:-${NONO_BIN:-nono}}"

die() {
  printf 'pi-box: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
pi-box - run Pi in a per-project nono capability sandbox

Usage:
pi-box                 start Pi in the current directory's sandbox
pi-box <pi args>       pass arguments to Pi (e.g. pi-box -p "run the tests")
pi-box init [template] scaffold pi-box.profile.json from a template
                       (defaults to the 'default' template)
pi-box init --force [template]
                       same, but overwrite an existing file after backing it up
pi-box init --list     list the available templates
pi-box profile         print the generated overlay profile and exit
pi-box help            show this help

Templates live in ~/.pi/sandbox/templates and are deployed by home-manager from
home-manager/pi-box-templates. An existing pi-box.profile.json is only replaced
when you confirm the prompt or pass --force, and the previous version is kept as
pi-box.profile.json.<YYYYmmdd-HHMMSS>.bak.

The static policy lives in ~/.config/nono/profiles/pi-box.json (deployed by
home-manager); a project's pi-box.profile.json extends it by name and is merged
by nono itself. This wrapper adds only the per-run overlay: workspace, worktree
git directory, repository root AGENTS.md, herdr socket, and the GitHub token
route. `pi-box profile` prints that overlay.
EOF
}

# --- overlay ----------------------------------------------------------------
#
# The overlay holds only what cannot be static in the deployed base profile.
build_overlay() {
  local workspace="$1" out="$2" herdr_socket="${3:-}"
  python3 - "$workspace" "$out" "$GH_TOKEN_FILE" "$herdr_socket" <<'PY'
import json
import os
import subprocess
import sys

(workspace, out_path, token_path, herdr_socket) = sys.argv[1:5]

allow = [workspace]
read_file = []
unix_sockets = []

# A worktree's .git file points outside the workspace; without the common dir git
# cannot read or write its own metadata. Pi also reads AGENTS.md from the
# repository root, which for a bare worktree layout is the common dir's parent.
dot_git = os.path.join(workspace, ".git")
if os.path.isfile(dot_git):
    try:
        common = subprocess.run(
            ["git", "-C", workspace, "rev-parse", "--path-format=absolute",
             "--git-common-dir"],
            capture_output=True, text=True, check=True).stdout.strip()
    except subprocess.CalledProcessError:
        common = ""
    if common and os.path.isdir(common):
        real = os.path.realpath(common)
        if not real.startswith(workspace.rstrip("/") + "/"):
            allow.append(real)
            agents = os.path.join(os.path.dirname(real), "AGENTS.md")
            if os.path.isfile(agents):
                read_file.append(agents)

if herdr_socket:
    unix_sockets.append(herdr_socket)

filesystem = {"allow": allow}
if read_file:
    filesystem["read_file"] = read_file
if unix_sockets:
    filesystem["unix_socket"] = unix_sockets

network = {}
# GitHub: the token stays in the supervisor, and only a phantom reaches the
# sandbox. Endpoint rules come from the base profile; this route only activates
# when the token file exists.
if os.path.exists(token_path):
    network = {
        "credentials": ["pi-box-github"],
        "custom_credentials": {
            "pi-box-github": {
                "upstream": "https://api.github.com",
                "credential_key": f"file://{token_path}",
                "env_var": "GH_TOKEN",
                "inject_header": "Authorization",
                "credential_format": "token {}",
                "endpoint_rules": [
                    {"method": "GET", "path": "/user"},
                    {"method": "GET", "path": "/repos/**"},
                    {"method": "GET", "path": "/search/**"},
                    {"method": "GET", "path": "/notifications"},
                    {"method": "POST", "path": "/repos/*/pulls"},
                    {"method": "POST", "path": "/copilot_internal/**"},
                    {"method": "POST", "path": "/graphql"},
                ],
            }
        },
    }

overlay = {
    "extends": "default",
    "meta": {"name": os.path.basename(out_path)[:-len(".json")]},
    "filesystem": filesystem,
}
if network:
    overlay["network"] = network

os.makedirs(os.path.dirname(out_path), exist_ok=True)
with open(out_path, "w") as handle:
    json.dump(overlay, handle, indent=2)
    handle.write("\n")
PY
}

# Stable overlay profile name per project, written next to the deployed base
# profile so nono can resolve it by name. Nono's name grammar excludes
# underscores, so collapse them to hyphens.
overlay_name() {
  local name
  name="$(basename "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//')"
  [ -n "$name" ] || name="project"
  printf 'pi-box-overlay-%s' "$name"
}

# --- run --------------------------------------------------------------------
#
# The sandboxed process inherits the host PATH, and nono's filtering of it is
# not something this wrapper controls: on NixOS every profile entry is a symlink
# farm, and what survives the filter is exactly what made `readlink: command not
# found` happen. Instead, a launcher script is generated into the runtime dir
# (granted read-only by the base profile) that sets its own PATH from entries
# the wrapper resolved host-side to /nix/store - the /nix grant makes those
# readable - and execs pi by absolute path. PATH and TMPDIR set inside the
# launcher are final; the supervisor keeps the original host PATH for its own
# broker resolution.
launcher_path() {
  # Colon list of original PATH entries whose targets resolve under /nix/store.
  local entry resolved result=""
  local IFS=:
  for entry in $PATH; do
    [ -n "$entry" ] || continue
    resolved="$(readlink -f "$entry" 2>/dev/null || true)"
    case "$resolved" in
      /nix/store/*) result="${result:+$result:}$resolved" ;;
    esac
  done
  printf '%s' "$result"
}

cmd_run() {
  local workspace
  workspace="$(pwd)"

  # Resolve pi host-side: the supervisor must not depend on PATH for it, and the
  # resolved path is either a Nix store path (readable via /nix) or the real
  # wrapper file under ~/.local/bin (readable via the user-tools group).
  local pi_bin
  pi_bin="$(command -v pi)" || die "pi not found on PATH"
  pi_bin="$(readlink -f "$pi_bin")"

  mkdir -p "$RUNTIME_DIR" "$TMP_DIR"
  # nixos-rebuild falls back to hardcoded /tmp when TMPDIR exceeds its 45-byte
  # SSH control-socket limit, which the sandbox denies. Export a short alias of
  # the scratch dir instead.
  local tmp_alias="$HOME/.pi-tmp"
  if [ ! -L "$tmp_alias" ] || [ "$(readlink "$tmp_alias" 2>/dev/null)" != "$TMP_DIR" ]; then
    rm -f "$tmp_alias"
    ln -s "$TMP_DIR" "$tmp_alias"
  fi
  local launcher="$RUNTIME_DIR/pi-launcher.sh"
  {
    printf '#!/usr/bin/env bash\n'
    printf 'export PATH="%s"\n' "$(launcher_path)"
    printf 'export TMPDIR="%s"\n' "$tmp_alias"
    printf 'exec %q "$@"\n' "$pi_bin"
  } >"$launcher"
  chmod +x "$launcher"

  # Herdr cannot see the agent process behind a sandbox wrapper, so tell it
  # which screen manifest to use for this pane. The hint lives on the host-side
  # foreground process, never in the profile.
  export HERDR_AGENT="${HERDR_AGENT:-pi}"

  local herdr_socket=""
  if [ "${HERDR_ENV:-}" = "1" ] && [ -n "${HERDR_SOCKET_PATH:-}" ]; then
    herdr_socket="$HERDR_SOCKET_PATH"
  fi

  # GitHub remotes written in SSH form work anyway: rewrite them to HTTPS inside
  # the sandbox only, so git uses the host credential helper instead of an SSH
  # agent the sandbox never receives. Each checkout keeps its configured origin.
  export GIT_CONFIG_COUNT=1
  export GIT_CONFIG_KEY_0="url.https://github.com/.insteadOf"
  export GIT_CONFIG_VALUE_0="git@github.com:"

  local overlay
  overlay="$(overlay_name "$workspace")"
  build_overlay "$workspace" "$HOME/.config/nono/profiles/$overlay.json" "$herdr_socket"

  # Project profile when present (it extends the deployed base by name);
  # otherwise the base profile itself.
  local profile="$BASE_PROFILE"
  if [ -f "$workspace/pi-box.profile.json" ]; then
    profile="$workspace/pi-box.profile.json"
  fi

  # Herdr detects the pane's agent by the foreground process. Nono must
  # therefore exec under the name `pi` - a symlink to the unwrapped ELF, with
  # argv[0] forced to `pi` - so the foreground reads as `pi` exactly like a host
  # pi pane, instead of `.nono-wrapped` or `nono`.
  local nono_bin
  nono_bin="$(command -v "$NONO")" || die "nono not found on PATH"
  ln -sf "$(readlink -f "$nono_bin")" "$RUNTIME_DIR/pi"
  exec -a pi "$RUNTIME_DIR/pi" run --profile "$profile" --extends "$overlay" -- "$launcher" "$@"
}

cmd_profile() {
  local workspace overlay
  workspace="$(pwd)"
  overlay="$(overlay_name "$workspace")"
  printf 'pi-box: static policy: %s (deployed by home-manager, "extends" target)\n' \
    "$HOME/.config/nono/profiles/$BASE_PROFILE.json" >&2
  build_overlay "$workspace" "$HOME/.config/nono/profiles/$overlay.json" ""
  cat "$HOME/.config/nono/profiles/$overlay.json"
}

# --- init -------------------------------------------------------------------
list_templates() {
  local dir
  for dir in "$TEMPLATE_DIR"/*/; do
    if [ -f "$dir/pi-box.profile.json" ]; then
      basename "$dir"
    fi
  done
}

cmd_init() {
  local template="default" force=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --list | -l)
        list_templates
        return 0
        ;;
      -f | --force)
        force=1
        ;;
      -*)
        die "unknown option: $1 (see: pi-box help)"
        ;;
      *)
        template="$1"
        ;;
    esac
    shift
  done

  local src="$TEMPLATE_DIR/$template/pi-box.profile.json"
  if [ ! -f "$src" ]; then
    local available
    available="$(list_templates | tr '\n' ' ')"
    [ -n "$available" ] || die "no templates found in $TEMPLATE_DIR (apply home-manager: make home)"
    die "unknown template '$template'; available: $available"
  fi

  local target="pi-box.profile.json"
  if [ -e "$target" ]; then
    local overwrite=0
    # One prompt, and without a terminal the answer is no: scripted runs must not
    # silently destroy files.
    if [ "$force" -eq 1 ]; then
      overwrite=1
    elif [ -t 0 ]; then
      printf 'pi-box: %s already exists. Back up and overwrite from template %s? [y/N] ' "$target" "$template" >&2
      local answer=""
      read -r answer || answer=""
      case "$answer" in
        [yY] | [yY][eE][sS]) overwrite=1 ;;
      esac
    else
      printf 'pi-box: %s already exists, and there is no terminal to ask; leaving it alone (use --force)\n' "$target" >&2
    fi
    if [ "$overwrite" -eq 0 ]; then
      return 0
    fi

    # shortcut: second-resolution stamp, so a second init within the same second
    # overwrites the earlier backup. Add a counter loop if that ever bites.
    local stamp
    stamp="$(date +%Y%m%d-%H%M%S)"
    cp -a "$target" "$target.$stamp.bak"
    printf 'pi-box: backed up %s -> %s.bak\n' "$target" "$target.$stamp" >&2
  fi

  # rm first: writing through a symlinked target would land outside the project.
  rm -f "$target"
  cp "$src" "$target"
  # Templates live in the Nix store, whose files are read-only; without this the
  # scaffold could not be edited after `init`.
  chmod u+w "$target"
  printf 'pi-box: created %s from template %s\n' "$target" "$template" >&2
}

# --- dispatch ---------------------------------------------------------------
case "${1:-}" in
  init)
    shift
    cmd_init "$@"
    ;;
  profile)
    cmd_profile
    ;;
  help | --help | -h)
    usage
    ;;
  "")
    cmd_run
    ;;
  -*)
    cmd_run "$@"
    ;;
  *)
    usage >&2
    die "unknown subcommand: $1"
    ;;
esac
