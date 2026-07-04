#!/usr/bin/env bash
# Regenerates OpenSpec agent integration files (skills, prompts, commands) for
# Pi and OpenCode using the currently installed openspec CLI.
#
# Usage: ./scripts/regenerate-openspec-agent-files.sh
#
# Runs `openspec init --tools pi,opencode --force` in a temp directory and copies
# the generated .pi/ and .opencode/ output into pkgs/openspec-agent-files/.
# This should be run before `make home-build` or `make home` to ensure the
# checked-in agent files match the installed openspec CLI version.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="$REPO_ROOT/pkgs/openspec-agent-files"

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

cd "$WORKDIR"
echo "==> Running openspec init --tools pi,opencode --force ..."
openspec init --tools pi,opencode --force > /dev/null 2>&1

echo "==> Copying generated files to $TARGET_DIR ..."
rm -rf "$TARGET_DIR/.pi" "$TARGET_DIR/.opencode"
cp -r .pi "$TARGET_DIR/.pi"
cp -r .opencode "$TARGET_DIR/.opencode"

echo "==> Done. Agent files regenerated from openspec $(openspec --version)."
