# Tasks

## 1. Add the Nix-configs template

- [ ] 1.1 Add `home-manager/pi-box-templates/nix-configs/Dockerfile.pi` and `pi-box.toml` with the flake-capable Nix toolchain, existing OpenSpec CLI pin, and named `/nix` volume; force-add both scaffold-named files and verify they are tracked.
- [ ] 1.2 Build the project image and verify `make`, `nix`, `nh`, `nixos-rebuild`, `nixpkgs-fmt`, and `openspec` are available and Nix has `nix-command` and `flakes` enabled.
- [ ] 1.3 Run a small Nix evaluation/build with Nix sandboxing enabled inside rootless Docker; verify no host `/nix` path or daemon socket is mounted, and a store path persists across two container runs using the named volume.

## 2. Update project instructions

- [ ] 2.1 Update `AGENTS.md` to permit `make format`, `make home-build`, `make os-build`, and `make update`, and reserve `make os`, `make os-boot`, `make home`, `make clean`, and `make os-test` for humans; verify the instructions contain exactly this policy and no Makefile guard is added.
- [ ] 2.2 Document the `nix-configs` template, deployment, `pi-box init --force nix-configs` adoption, and named-volume cleanup; verify the documented template and volume names match their files.

## 3. Deploy and verify the workflow

- [ ] 3.1 After a human applies Home Manager with `make home`, run `pi-box init --force nix-configs` in this worktree; verify it backs up the existing ignored `Dockerfile.pi` and creates the new project Dockerfile and manifest.
- [ ] 3.2 Run `make format`, `make home-build`, and `make os-build` inside pi-box; verify each succeeds and review any workspace diff for unintended changes.
- [ ] 3.3 Run `make update` in a disposable copy of the worktree; verify the lockfile update succeeds there and leaves the original worktree's `flake.lock` unchanged.
