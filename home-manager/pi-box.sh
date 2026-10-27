#!/usr/bin/env bash
# pi-box - run the Pi coding agent in a per-project rootless-Docker sandbox.
#
# Installed by home-manager/pi-sandbox.nix. The base image Dockerfile is
# deployed alongside it to ~/.pi/sandbox/Dockerfile; per-project images extend
# it via an untracked Dockerfile.pi in the project directory.
#
# Default grants: the project directory (read-write, at its host absolute path),
# ~/.pi/agent (read-write, shared Pi identity and state), ~/.config/git
# (read-only), ~/.config/gh (read-only). Never granted: ~/.aws, ~/.ssh, the
# 1Password agent socket, or any other host path.
#
# Extra grants come only from an untracked pi-box.toml in the project directory.
#
# Inside a herdr pane the sandbox also gets a filtered relay socket for agent
# state reporting; herdr's API socket itself is never mounted.

set -euo pipefail

# Pinned by home-manager/pi-sandbox.nix.
PI_VERSION="__PI_VERSION__"

SANDBOX_DIR="${PI_BOX_SANDBOX_DIR:-$HOME/.pi/sandbox}"
BASE_DOCKERFILE="$SANDBOX_DIR/Dockerfile"
TEMPLATE_DIR="$SANDBOX_DIR/templates"
GH_TOKEN_FILE="$SANDBOX_DIR/gh-token"
BASE_IMAGE="pi-sandbox"
PI_STATE_DIR="$HOME/.pi/agent"
CONTAINER_PI_STATE_DIR="/root/.pi/agent"
GIT_CONFIG_DIR="$HOME/.config/git"
GH_CONFIG_DIR="$HOME/.config/gh"
RELAY_SCRIPT="$SANDBOX_DIR/pi-herdr-relay.py"
CONTAINER_RELAY_SOCKET="/run/pi-box/herdr-relay.sock"

die() {
  printf 'pi-box: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
pi-box - run Pi in a per-project rootless-Docker sandbox

Usage:
pi-box                 start Pi in the current directory's sandbox
pi-box <pi args>       pass arguments to Pi (e.g. pi-box -p "run the tests")
pi-box init [template] scaffold Dockerfile.pi and pi-box.toml from a template
                       (defaults to the 'default' template)
pi-box init --force [template]
                       same, but overwrite existing files after backing them up
pi-box init --list     list the available templates
pi-box help            show this help

Templates live in ~/.pi/sandbox/templates and are deployed by home-manager from
home-manager/pi-box-templates. A project's files are only replaced when you
confirm the prompt or pass --force, and the previous versions are kept as
<file>.<YYYYmmdd-HHMMSS>.bak, all backups of one run sharing one timestamp.

Default grants: the project directory (read-write), ~/.pi/agent (read-write),
~/.config/git (read-only), ~/.config/gh (read-only). ~/.aws, ~/.ssh and the
1Password socket are never mounted. Add grants with pi-box.toml.

The base image is rebuilt on every run; Docker layer caching makes that a no-op
unless the Dockerfile or --build-arg changed. Rebuild it after upgrading Pi.
EOF
}

# --- manifest ---------------------------------------------------------------
#
# pi-box.toml declares grants beyond the default set; the schema is documented in
# the init template below. yq parses it as real TOML, so quoting, comments, types
# and multi-line values behave as TOML specifies rather than as a hand-rolled
# parser guesses. Records are emitted as TAB-separated `KIND<TAB>value` lines:
#
#   PORT <spec>   MOUNT <path>   VOLUME <spec>   ENV <key=value>   GH <bool>
#
# A key that is absent produces no record, so the caller's defaults stand (gh
# defaults to on).
parse_manifest() {
  yq -p toml -o json -r '
    (.ports[]? | "PORT\t" + tostring),
    (.mounts[]? | "MOUNT\t" + tostring),
    (.volumes[]? | "VOLUME\t" + tostring),
    ((.env // {}) | to_entries | .[] | "ENV\t" + .key + "=" + (.value | tostring)),
    (select(has("gh")) | "GH\t" + (.gh | tostring))
  ' "$1"
}

# --- images -----------------------------------------------------------------
build_base_image() {
  [ -f "$BASE_DOCKERFILE" ] || die "base Dockerfile missing at $BASE_DOCKERFILE (apply home-manager: make home)"
  # The deployed Dockerfile is a symlink into the Nix store, which BuildKit
  # cannot read from the build context, so feed it on stdin instead.
  docker build \
    --file - \
    --tag "$BASE_IMAGE" \
    --build-arg "PI_VERSION=$PI_VERSION" \
    "$SANDBOX_DIR" <"$BASE_DOCKERFILE"
}

project_image_tag() {
  local name
  name="$(basename "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_.-]/-/g')"
  printf 'pi-%s' "$name"
}

# Address the container uses to reach host services.
# Rootless Docker's `host-gateway` resolves to the inner bridge address, which
# does not reach services bound on the host, so prefer the source address of the
# default route and fall back to host-gateway when it cannot be determined.
host_gateway_address() {
  local address
  address="$(ip -4 route get 1.1.1.1 2>/dev/null | sed -n 's/.* src \([0-9.]*\).*/\1/p')"
  if [ -n "$address" ]; then
    printf '%s' "$address"
  else
    printf 'host-gateway'
  fi
}

# Mount a git common dir that lives outside the workspace read-write.
# In a bare-repository worktree layout the worktree's `.git` is a file pointing at
# `<repo>/.bare/worktrees/<name>`, so mounting only the project directory leaves
# git unable to read or write its own metadata inside the sandbox.
append_gitdir_mount() {
  local workspace="$1" common

  # Only the `.git`-file layouts (worktree, submodule) can point outside.
  [ -f "$workspace/.git" ] || return 0

  common="$(git -C "$workspace" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
  [ -n "$common" ] || return 0
  common="$(readlink -f "$common" 2>/dev/null || printf '%s' "$common")"
  [ -d "$common" ] || return 0

  # Already covered by the workspace mount.
  case "$common/" in
    "$workspace"/*) return 0 ;;
  esac

  args+=(--volume "$common:$common")
}

# Mount a host config directory read-only, plus each of its symlinked entries.
# Home-manager deploys files as symlinks into the Nix store; the targets do not
# exist inside the container, so a mount over the symlink path is what makes
# them readable. Optional third argument limits the pass to one file name.
append_config_mounts() {
  local host_dir="$1" container_dir="$2" only="${3:-}"
  [ -d "$host_dir" ] || return 0

  local entry resolved
  if [ -n "$only" ]; then
    entry="$host_dir/$only"
    [ -L "$entry" ] || return 0
    resolved="$(readlink -f "$entry" || true)"
    if [ -n "$resolved" ] && [ -f "$resolved" ]; then
      args+=(--volume "$resolved:$container_dir/$only:ro")
    fi
    return 0
  fi

  args+=(--volume "$host_dir:$container_dir:ro")

  for entry in "$host_dir"/*; do
    [ -L "$entry" ] || continue
    resolved="$(readlink -f "$entry" || true)"
    [ -n "$resolved" ] && [ -f "$resolved" ] || continue
    args+=(--volume "$resolved:$container_dir/$(basename "$entry"):ro")
  done
}

# Map a host Pi state path to the container view for --session arguments.
# Herdr's restart-resume types the host path; the same file is mounted inside.
map_session_path() {
  case "${1:-}" in
    "$PI_STATE_DIR"/*) printf '%s/%s' "$CONTAINER_PI_STATE_DIR" "${1#"$PI_STATE_DIR"/}" ;;
    *) printf '%s' "${1:-}" ;;
  esac
}

# --- run --------------------------------------------------------------------
cmd_run() {
  local workspace pi_args=()
  workspace="$(pwd)"
  pi_args=("$@")

  # Herdr cannot see the agent process behind a sandbox wrapper, so tell it
  # which screen manifest to use for this pane. The hint lives on the host-side
  # foreground process (this script, then the exec'd docker), never inside the
  # container. Override with HERDR_AGENT=... when invoking pi-box.
  export HERDR_AGENT="${HERDR_AGENT:-pi}"

  build_base_image

  local image="$BASE_IMAGE"
  if [ -f "$workspace/Dockerfile.pi" ]; then
    image="$(project_image_tag "$workspace")"
    docker build --file "$workspace/Dockerfile.pi" --tag "$image" "$workspace"
  else
    printf 'pi-box: no Dockerfile.pi in %s, using the base image\n' "$workspace" >&2
  fi

  local -a ports=() mounts=() envs=() volumes=()
  local gh_enabled=1
  if [ -f "$workspace/pi-box.toml" ]; then
    local kind value
    while IFS=$'\t' read -r kind value; do
      case "$kind" in
        PORT) ports+=("$value") ;;
        MOUNT) mounts+=("$value") ;;
        VOLUME) volumes+=("$value") ;;
        ENV) envs+=("$value") ;;
        GH)
          case "$value" in
            false | False | FALSE | 0 | no | off) gh_enabled=0 ;;
            *) gh_enabled=1 ;;
          esac
          ;;
      esac
    done < <(parse_manifest "$workspace/pi-box.toml")
  fi

  local -a args=(run --rm --interactive --workdir "$workspace")
  if [ -t 0 ] && [ -t 1 ]; then
    args+=(--tty)
  fi
  args+=(--add-host "host.docker.internal:$(host_gateway_address)")
  args+=(--volume "$workspace:$workspace")
  args+=(--volume "$PI_STATE_DIR:$CONTAINER_PI_STATE_DIR")
  append_gitdir_mount "$workspace"

  # Home-manager deploys these as symlinks into the Nix store, whose targets do
  # not exist inside the container. Mount the directory, then mount each
  # symlink's resolved target over the symlink's own container path.
  append_config_mounts "$PI_STATE_DIR" "/root/.pi/agent" "AGENTS.md"
  append_config_mounts "$GIT_CONFIG_DIR" "/root/.config/git"
  if [ "$gh_enabled" -eq 1 ]; then
    append_config_mounts "$GH_CONFIG_DIR" "/root/.config/gh"
  fi

  local item
  for item in ${ports[@]+"${ports[@]}"}; do
    args+=(--publish "$item")
  done
  for item in ${mounts[@]+"${mounts[@]}"}; do
    args+=(--volume "$item:$item:ro")
  done
  for item in ${volumes[@]+"${volumes[@]}"}; do
    args+=(--volume "$item")
  done
  for item in ${envs[@]+"${envs[@]}"}; do
    args+=(--env "$item")
  done

  # Herdr state reporting: the sandbox gets a filtered relay socket instead of
  # the herdr API socket, which can read and drive every pane. The relay
  # forwards only this pane's agent state reports and maps reported session
  # paths back to the host view so restart-resume stores a usable path.
  local relay_pid="" relay_socket=""
  if [ "${HERDR_ENV:-}" = "1" ] && [ -n "${HERDR_PANE_ID:-}" ] && [ -n "${HERDR_SOCKET_PATH:-}" ]; then
    [ -f "$RELAY_SCRIPT" ] || die "relay script missing at $RELAY_SCRIPT (apply home-manager: make home)"
    relay_socket="$SANDBOX_DIR/relay-$(printf '%s' "$HERDR_PANE_ID" | tr -c '[:alnum:]._-' '-').sock"
    rm -f "$relay_socket"
    python3 "$RELAY_SCRIPT" \
      --socket "$relay_socket" \
      --api-socket "$HERDR_SOCKET_PATH" \
      --pane-id "$HERDR_PANE_ID" \
      --host-state-dir "$PI_STATE_DIR" &
    relay_pid=$!
    local waited=0
    while [ ! -S "$relay_socket" ]; do
      if [ "$waited" -ge 200 ] || ! kill -0 "$relay_pid" 2>/dev/null; then
        printf 'pi-box: warning: herdr relay did not start; agent states fall back to screen detection\n' >&2
        break
      fi
      sleep 0.01
      waited=$((waited + 1))
    done
    if [ -S "$relay_socket" ]; then
      args+=(--env "HERDR_ENV=1" --env "HERDR_PANE_ID=$HERDR_PANE_ID")
      args+=(--env "HERDR_SOCKET_PATH=$CONTAINER_RELAY_SOCKET")
      args+=(--volume "$relay_socket:$CONTAINER_RELAY_SOCKET")
    fi
  fi

  # Invoked indirectly by the EXIT trap below.
  # shellcheck disable=SC2329
  cleanup_relay() {
    if [ -n "$relay_pid" ]; then
      kill "$relay_pid" 2>/dev/null || true
      wait "$relay_pid" 2>/dev/null || true
      relay_pid=""
    fi
    if [ -n "$relay_socket" ]; then
      rm -f "$relay_socket"
    fi
  }
  trap cleanup_relay EXIT

  # GitHub token: the host's gh keeps its credential in the OS keyring, which
  # does not cross into the container, and ~/.config/gh/hosts.yml carries only
  # settings. A fine-grained read-only token is mounted as a file instead, and
  # exported inside the container so it never shows up in `docker inspect` or
  # the host process list.
  local -a command=(pi)
  if [ -f "$GH_TOKEN_FILE" ]; then
    case "$(stat -Lc '%a' "$GH_TOKEN_FILE")" in
      600 | 400) ;;
      *) printf 'pi-box: warning: %s is readable by others (chmod 600 it)\n' "$GH_TOKEN_FILE" >&2 ;;
    esac
    args+=(--volume "$GH_TOKEN_FILE:/run/pi-box/gh-token:ro")
    # The single quotes are deliberate: the container-side shell expands these.
    # shellcheck disable=SC2016
    command=(sh -c 'if [ -r /run/pi-box/gh-token ]; then GH_TOKEN="$(cat /run/pi-box/gh-token)"; export GH_TOKEN; fi; exec pi "$@"' pi-box)
  fi

  # Session paths herdr types for restart-resume point at the host Pi state
  # directory; map them to the container view. Ids and other args pass through.
  local -a sandbox_pi_args=()
  local idx=0 arg
  while [ "$idx" -lt "${#pi_args[@]}" ]; do
    arg="${pi_args[$idx]}"
    idx=$((idx + 1))
    case "$arg" in
      --session=*)
        sandbox_pi_args+=("--session=$(map_session_path "${arg#--session=}")")
        ;;
      --session)
        sandbox_pi_args+=("--session")
        if [ "$idx" -lt "${#pi_args[@]}" ]; then
          sandbox_pi_args+=("$(map_session_path "${pi_args[$idx]}")")
          idx=$((idx + 1))
        fi
        ;;
      *)
        sandbox_pi_args+=("$arg")
        ;;
    esac
  done

  args+=("$image" "${command[@]}" ${sandbox_pi_args[@]+"${sandbox_pi_args[@]}"})
  local status=0
  docker "${args[@]}" || status=$?
  exit "$status"
}

# --- init -------------------------------------------------------------------
# Templates are deployed by home-manager alongside the base Dockerfile; the
# repository copy under home-manager/pi-box-templates is the source of truth.
list_templates() {
  local dir
  for dir in "$TEMPLATE_DIR"/*/; do
    if [ -f "$dir/Dockerfile.pi" ]; then
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

  local template_dir="$TEMPLATE_DIR/$template" docker_src manifest_src
  if [ ! -f "$template_dir/Dockerfile.pi" ]; then
    local available
    available="$(list_templates | tr '\n' ' ')"
    [ -n "$available" ] || die "no templates found in $TEMPLATE_DIR (apply home-manager: make home)"
    die "unknown template '$template'; available: $available"
  fi
  docker_src="$template_dir/Dockerfile.pi"
  # A template may omit the manifest; the generic one then applies.
  manifest_src="$template_dir/pi-box.toml"
  [ -f "$manifest_src" ] || manifest_src="$TEMPLATE_DIR/default/pi-box.toml"
  [ -f "$manifest_src" ] \
    || die "default manifest missing at $TEMPLATE_DIR/default/pi-box.toml (apply home-manager: make home)"

  local -a targets=(Dockerfile.pi pi-box.toml) sources=("$docker_src" "$manifest_src")
  local i path overwrite=0
  local -a existing=()
  for path in "${targets[@]}"; do
    if [ -e "$path" ]; then
      existing+=("$path")
    fi
  done

  # One prompt for the whole batch, so a single answer decides the run and all
  # backups share one timestamp. Without a terminal the answer is no: scripted
  # runs must not silently destroy files.
  if [ "${#existing[@]}" -gt 0 ]; then
    if [ "$force" -eq 1 ]; then
      overwrite=1
    elif [ -t 0 ]; then
      printf 'pi-box: found existing %s. Back up and overwrite from template %s? [y/N] ' "${existing[*]}" "$template" >&2
      local answer=""
      read -r answer || answer=""
      case "$answer" in
        [yY] | [yY][eE][sS]) overwrite=1 ;;
      esac
    else
      printf 'pi-box: %s already exists, and there is no terminal to ask; leaving it alone (use --force)\n' "${existing[*]}" >&2
    fi
    if [ "$overwrite" -eq 0 ]; then
      return 0
    fi

    # shortcut: second-resolution stamp, so a second init within the same second
    # overwrites the earlier backup. Add a counter loop if that ever bites.
    local stamp
    stamp="$(date +%Y%m%d-%H%M%S)"
    for path in "${existing[@]}"; do
      cp -a "$path" "$path.$stamp.bak"
      printf 'pi-box: backed up %s -> %s.bak\n' "$path" "$path.$stamp" >&2
    done
  fi

  for i in "${!targets[@]}"; do
    # rm first: writing through a symlinked target would land outside the project.
    rm -f "${targets[$i]}"
    cp "${sources[$i]}" "${targets[$i]}"
    printf 'pi-box: created %s from template %s\n' "${targets[$i]}" "$template" >&2
  done
}

# --- dispatch ---------------------------------------------------------------
case "${1:-}" in
  init)
    shift
    cmd_init "$@"
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
