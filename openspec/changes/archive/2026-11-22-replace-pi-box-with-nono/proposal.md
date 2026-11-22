# Proposal

## Why

pi-box's Docker-based sandbox carries ~900 lines of machinery (image builds, mount plumbing, a herdr relay, a token-file workaround) and leaves one documented risk unsolved: the sandbox GitHub token is a write-capable classic PAT with no read-only scope, so sandboxed Pi can push to every private repo the token reaches. Nono provides kernel-enforced capability sandboxing that keeps pi-box's absence-style confidentiality model while adding default-deny network, per-tool policies, and brokered credentials with endpoint rules - the first mechanism that can constrain what that write-capable token is actually used for.

## What Changes

- The `pi-box` wrapper is reimplemented to launch Pi via `nono run --profile <generated> -- pi` instead of building and running Docker containers. The name, UX (`pi-box`, `pi-box <args>`, `pi-box init`), and herdr restart-resume routing stay.
- The per-project scaffold becomes a nono profile instead of `Dockerfile.pi` + `pi-box.toml`. **BREAKING**: existing scaffolds stop working; `pi-box init` re-scaffolds. **BREAKING**: `privileged`, named volumes, `host.docker.internal`, and published ports are replaced by nono equivalents or dropped; per-project host-DB access moves to localhost with opted-in ports.
- Toolchain templates (php83, php82, java8, node22) stop shipping Dockerfiles; the sandboxed agent uses host tools and the project's devShells. The nix-configs template's private Nix store volume is dropped in favor of the host Nix.
- GitHub auth moves from the mounted token file to nono credential injection: the token stays outside the sandbox and endpoint rules scope its use (read issues/PRs, create PRs on the work orgs, deny destructive endpoints).
- Network becomes default-deny with an allowlist (LLM APIs, GitHub, package registries). **BREAKING**: the sandbox no longer has unrestricted internet; blocked domains surface in nono's audit trail.
- Deleted: the base-image Dockerfile, the herdr relay script, all template Dockerfiles, token-file plumbing, and the container-side git remote rewrite.
- The never-grant guarantees (~/.aws, ~/.ssh, the 1Password agent socket) are kept, now expressed as absent grants in the generated profile rather than absent mounts.
- Pi's version pin moves from an image build-arg to the home-manager Pi package.
- Home Manager installs `pkgs.nono` (nixpkgs 26.05); rootless Docker is no longer used by pi-box.

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `pi-box-sandbox`: the sandbox mechanism changes from a rootless-Docker container to a nono capability sandbox. Requirements change for launch, the grant set, credentials, network access, herdr reporting, init scaffolding, and Pi version pinning; Docker-specific requirements are removed.
- `pi-box-templates`: templates change from Dockerfile-based toolchain images to nono profile templates; toolchain provisioning and the nix-configs template requirements change.

## Impact

- `home-manager/pi-sandbox.nix` (module: nono package, generated profile deployment), `home-manager/pi-box.sh` (full rewrite), `home-manager/pi-sandbox.Dockerfile` and `home-manager/pi-herdr-relay.py` (deleted), `home-manager/pi-box-templates/` (rewritten as profile templates), `home-manager/zsh.nix` (routing preserved), `home-manager/git.nix` (scaffold ignore list).
- New dependency: `nono` from nixpkgs 26.05 (pre-1.0, fast version churn - pin deliberately, expect profile-schema drift).
- Host requirement: Linux kernel 5.13+ with Landlock (satisfied by this NixOS host).
- Documentation: AGENTS.md pi-box section, openwiki operations page, and the two spec files.
- Open questions to resolve during design: `nix build` behavior under nono for the nix-configs template, gh OS-keyring auth through the nono supervisor, and herdr pane/agent-state behavior (all spikeable).
