#!/usr/bin/env bash
# Regression check for pi-box's per-run overlay and PHP templates.
# Run: bash home-manager/pi-box-check.sh
#
# Covers the Git metadata grants the wrapper derives from the workspace:
# a workspace nested inside a repository must get its external .git read-only,
# and nothing else outside the workspace. Also covers the PHP templates, which
# must keep DB_HOST without narrowing the base's default-allow outbound network
# (network.connect_port on Linux is a TCP allowlist, so it blocks port 443).
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
wrapper="$here/pi-box.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# A workspace nested inside a repository: no .git of its own, metadata above it.
repo="$tmp/repo"
git init -q "$repo"
mkdir -p "$repo/nested/project" "$repo/nested/elsewhere"
export HOME="$tmp/home"
export PI_BOX_SANDBOX_DIR="$tmp/sandbox"

overlay="$(cd "$repo/nested/project" && bash "$wrapper" profile 2>/dev/null)"

python3 - "$overlay" "$repo/nested/project" "$repo" <<'PY'
import json
import sys

overlay, workspace, repo = (sys.argv[1], sys.argv[2], sys.argv[3])
granted = json.loads(overlay)["filesystem"]
git_dir = f"{repo}/.git"

def fail(message):
    print(f"FAIL: {message}")
    sys.exit(1)

if granted.get("allow") != [workspace]:
    fail(f"filesystem.allow should be the workspace only, got {granted.get('allow')}")

if git_dir not in granted.get("read", []):
    fail(f"external .git missing from filesystem.read: {granted}")

if f"{repo}/nested/elsewhere" in granted.get("read", []):
    fail("an unrelated parent path was granted")

print("ok: nested workspace gets its external .git read-only")
PY

php_templates=("$here"/pi-box-templates/php82/pi-box.profile.json "$here"/pi-box-templates/php83/pi-box.profile.json)

python3 - "${php_templates[@]}" <<'PY'
import json
import sys

for path in sys.argv[1:]:
    with open(path) as handle:
        profile = json.load(handle)

    if "connect_port" in profile.get("network", {}):
        print(f"FAIL: {path} restricts outbound TCP with network.connect_port")
        sys.exit(1)

    db_host = profile.get("environment", {}).get("set_vars", {}).get("DB_HOST")
    if db_host != "127.0.0.1":
        print(f"FAIL: {path} should set DB_HOST=127.0.0.1, got {db_host!r}")
        sys.exit(1)

print("ok: PHP templates keep default outbound network and DB_HOST")
PY
