# Proposal

## Why

The `ka_alpha` workspace's Linux sync script clones and fetches seven linked GitHub repositories using `git@github.com:` remotes. Those operations fail in pi-box because the sandbox deliberately does not receive the host's SSH/1Password agent, even though the existing mounted-token `gh` HTTPS credential helper can access all seven repositories. A transparent GitHub URL rewrite lets the existing repos sync in the sandbox without changing their remote configuration or weakening the no-SSH-identity boundary.

## What Changes

- Add a Git URL rewrite to the shared pi-box base image so GitHub SCP-style SSH URLs (`git@github.com:ORG/REPO.git`) use HTTPS and the existing in-container `gh auth git-credential` helper.
- Add a per-project `Dockerfile.pi` for `/home/tung/code/knowledge-assistant/ka_alpha`, extending `pi-sandbox` with `@sysid/mmdlint`, which that workspace's instructions require for Mermaid validation.
- Verify the ka_alpha sync flow against all seven configured repos inside pi-box, without mounting SSH credentials or rewriting each clone's `origin`.
- Update pi-box documentation to explain the GitHub URL rewrite and its scope. Leave non-GitHub remotes and the Windows PowerShell sync script unchanged.

## Capabilities

### New Capabilities

<!-- None. This extends the existing pi-box-sandbox capability. -->

### Modified Capabilities

- `pi-box-sandbox`: add support for Git operations against GitHub SCP-style SSH remotes by transparently rewriting them to HTTPS and authenticating through the existing in-container gh credential helper.

## Impact

- `home-manager/pi-sandbox.Dockerfile`: add a GitHub-specific `url.*.insteadOf` rule to the baked `/root/.gitconfig`.
- `openspec/specs/pi-box-sandbox/spec.md`: add the SSH-form GitHub remote behavior to the existing capability contract.
- `AGENTS.md`: document transparent rewriting and clarify that other SSH hosts/protocol forms still need their own credentials or HTTPS remotes.
- Outside this repo, explicitly selected as the integration pilot: `/home/tung/code/knowledge-assistant/ka_alpha/Dockerfile.pi` (created using `pi-box init`, then extended with mmdlint). The existing `scripts/sync-repos.sh` and each linked repository's `.git/config` remain unchanged.
- Runtime credentials and mounts do not change: GitHub operations continue to use the existing read-only PAT file and gh credential helper; the host SSH/1Password socket remains unmounted.
