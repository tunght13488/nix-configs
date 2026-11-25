# Proposal

## Why

Pi-box currently grants the workspace and handles external Git metadata only when the workspace itself has a `.git` file. A workspace whose repository metadata is in a parent directory can therefore be unable to read that metadata. Granting only the required parent `.git` path read-only preserves the sandbox boundary while enabling Git inspection.

## What Changes

- Add a narrowly scoped read-only grant for parent `.git` metadata outside the workspace when it is not already covered by the existing worktree grant.
- Keep unrelated parent paths and write access to that metadata unavailable.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `pi-box-sandbox`: require read-only access to necessary parent-level Git metadata outside the workspace.

## Impact

- `home-manager/pi-box.sh`: per-run overlay generation and a regression check for the parent-metadata case.
- `openspec/specs/pi-box-sandbox`: update the least-privilege Git metadata grant contract.
