# Tasks

## 1. Parent `.git` access

- [ ] 1.1 Add a focused regression check that runs `pi-box profile` from a temporary workspace nested under a Git repository and asserts the external `.git` path is read-only, not in `filesystem.allow`, and unrelated parent paths are absent; verify the check reproduces the current missing grant.
- [ ] 1.2 Update `home-manager/pi-box.sh` to discover external Git metadata for nested workspaces and add only a read grant when it is not already covered by the existing worktree grant; run the regression check and verify existing worktree behavior remains unchanged.

## 2. Build validation

- [ ] 2.1 Run `make home-build` and confirm the Home Manager configuration evaluates successfully with the updated wrapper.
