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

set -euo pipefail

# Pinned by home-manager/pi-sandbox.nix.
PI_VERSION="__PI_VERSION__"

SANDBOX_DIR="${PI_BOX_SANDBOX_DIR:-$HOME/.pi/sandbox}"
BASE_DOCKERFILE="$SANDBOX_DIR/Dockerfile"
GH_TOKEN_FILE="$SANDBOX_DIR/gh-token"
BASE_IMAGE="pi-sandbox"
PI_STATE_DIR="$HOME/.pi/agent"
GIT_CONFIG_DIR="$HOME/.config/git"
GH_CONFIG_DIR="$HOME/.config/gh"

die() {
  printf 'pi-box: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
pi-box - run Pi in a per-project rootless-Docker sandbox

Usage:
pi-box                start Pi in the current directory's sandbox
pi-box <pi args>      pass arguments to Pi (e.g. pi-box -p "run the tests")
pi-box init           scaffold Dockerfile.pi and pi-box.toml here
pi-box help           show this help

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
#   PORT <spec>   MOUNT <path>   ENV <key=value>   GH <bool>
#
# A key that is absent produces no record, so the caller's defaults stand (gh
# defaults to on).
parse_manifest() {
  yq -p toml -o json -r '
    (.ports[]? | "PORT\t" + tostring),
    (.mounts[]? | "MOUNT\t" + tostring),
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

  local -a ports=() mounts=() envs=()
  local gh_enabled=1
  if [ -f "$workspace/pi-box.toml" ]; then
    local kind value
    while IFS=$'\t' read -r kind value; do
      case "$kind" in
        PORT) ports+=("$value") ;;
        MOUNT) mounts+=("$value") ;;
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
  args+=(--volume "$PI_STATE_DIR:/root/.pi/agent")
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
  for item in ${envs[@]+"${envs[@]}"}; do
    args+=(--env "$item")
  done

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
    command=(sh -c 'if [ -r /run/pi-box/gh-token ]; then GH_TOKEN="$(cat /run/pi-box/gh-token)"; export GH_TOKEN; fi; exec pi "$@"' pi-box)
  fi

  args+=("$image" "${command[@]}" ${pi_args[@]+"${pi_args[@]}"})
  exec docker "${args[@]}"
}

# --- init -------------------------------------------------------------------
DOCKERFILE_TEMPLATE='# Per-project pi-box image, automatically built and used by `pi-box`.
# The shared base (git, gh, rg, fd, node, pi) is ~/.pi/sandbox/Dockerfile.
FROM pi-sandbox

# Install the project toolchain below. Keep stable setup first: everything above
# the slowest-changing step stays cached across rebuilds.
USER root

# Example: PHP 8.3 from sury.org (Debian does not ship 8.3 in its own repos).
# RUN apt-get update && apt-get install -y --no-install-recommends \
#       ca-certificates curl gnupg lsb-release \
#     && curl -fsSL https://packages.sury.org/php/apt.gpg \
#        -o /usr/share/keyrings/sury-php.gpg \
#     && echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" \
#        > /etc/apt/sources.list.d/sury-php.list \
#     && apt-get update && apt-get install -y --no-install-recommends \
#       php8.3-cli php8.3-mbstring php8.3-mysql php8.3-soap php8.3-xml \
#       composer \
#     && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
'

MANIFEST_TEMPLATE='# pi-box manifest - grants beyond the default sandbox access.
#
# Default grants (no manifest needed): the project directory (read-write),
# ~/.pi/agent (read-write), ~/.config/git (read-only), ~/.config/gh
# (read-only). ~/.aws, ~/.ssh and the 1Password socket are never mounted.
#
# Grants:
#   ports  = ["8080:8080"]     publish container ports to the host
#   mounts = ["/host/path"]    extra read-only host mounts, at the same path
#   gh     = false             drop the ~/.config/gh GitHub identity mount
#
# [env] passes extra environment variables into the container.
# host.docker.internal reaches services on the host, such as MySQL.

gh = true

ports = []

mounts = []

[env]
# DB_HOST = "host.docker.internal"
'

cmd_init() {
  local created=0 path
  for path in Dockerfile.pi pi-box.toml; do
    if [ -e "$path" ]; then
      printf 'pi-box: %s already exists, leaving it alone\n' "$path" >&2
      continue
    fi
    if [ "$path" = "Dockerfile.pi" ]; then
      printf '%s' "$DOCKERFILE_TEMPLATE" >"$path"
    else
      printf '%s' "$MANIFEST_TEMPLATE" >"$path"
    fi
    printf 'pi-box: created %s\n' "$path" >&2
    created=1
  done
  if [ "$created" -eq 0 ]; then
    printf 'pi-box: nothing to do\n' >&2
  fi
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
