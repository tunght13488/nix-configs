# Design

## Context

See `proposal.md` for motivation. `home-manager/pi-box.sh` generates a per-run overlay: it grants the workspace read-write and currently adds an external Git common directory read-write only when the workspace itself has a `.git` file. Workspace-specific paths do not belong in the shared base profile.

## Goals / Non-Goals

**Goals:**
- Add read-only access to the external parent `.git` metadata needed by the workspace.
- Keep the grant limited to that metadata path and preserve existing worktree grants.

**Non-Goals:**
- Grant access to the parent directory or its other contents.
- Make parent Git metadata writable or change per-project manifest defaults.

## Decisions

- Resolve the repository metadata path host-side while generating the overlay. Add a read-only grant only when the resolved path is outside the workspace and is not already covered by an existing worktree grant. Use the profile's directory-read or single-file-read field according to the resolved path type. If the workspace is not in a Git repository, add no grant.
- Keep the existing read-write grant for the external common directory of a worktree. A broader parent-directory grant is simpler but exposes unrelated files; requiring each project to add a manual grant would not fix the default pi-box behavior.
- Add a focused regression check using a temporary repository with a workspace below its root. Verify the generated overlay grants only the external `.git` path read-only, leaves it out of `filesystem.allow`, and does not grant unrelated parent paths.

## Risks / Trade-offs

- Read-only metadata access does not enable Git operations that need to update that metadata, such as commits. This is intentional; the requested grant is read-only.
- Git worktree layouts may already cover the resolved path through the existing read-write grant. Avoid adding a redundant read grant and retain current worktree behavior.

## Migration Plan

No project profile migration is needed. The updated wrapper generates the grant on the next `pi-box` invocation; reverting the Home Manager generation removes the behavior.
