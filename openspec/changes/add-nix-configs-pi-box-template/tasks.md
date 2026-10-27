# Tasks

## 1. Add the Nix-configs template

- [x] 1.1 Add `home-manager/pi-box-templates/nix-configs/Dockerfile.pi` and `pi-box.toml` with the flake-capable Nix toolchain, existing OpenSpec CLI pin, and named `/nix` volume; force-add both scaffold-named files and verify they are tracked.
- [x] 1.2 Build the project image and verify `make`, `nix`, `nh`, `nixos-rebuild`, `nixpkgs-fmt`, and `openspec` are available and Nix has `nix-command` and `flakes` enabled.
- [x] 1.3 Add the `privileged` manifest grant to `home-manager/pi-box.sh` (parser, run arguments, help text) and set it in the template manifest; verify a sandboxed `docker run` argument list contains `--privileged` only when the manifest declares it.
- [x] 1.4 Verify a Nix build completes with sandboxing enabled inside rootless Docker, that a store path persists across two runs of the named volume, and that no host `/nix` path or daemon socket is mounted.

## 2. Update project instructions

- [x] 2.1 Update `AGENTS.md` to permit `make format`, `make home-build`, `make os-build`, and `make update`, and reserve `make os`, `make os-boot`, `make home`, `make clean`, and `make os-test` for humans; verify the instructions contain exactly this policy and no Makefile guard is added.
- [x] 2.2 Document the `nix-configs` template, the `privileged` grant and why Nix needs it, `pi-box init --force nix-configs` adoption, and the named-volume cleanup; verify the documented template, grant, and volume names match their files.

## 3. Deploy and verify the workflow

- [ ] 3.1 After a human applies Home Manager with `make home`, run `pi-box init --force nix-configs` in this worktree; verify it backs up the existing ignored `Dockerfile.pi` and creates the new project Dockerfile and manifest.
- [ ] 3.2 Run `make format`, `make home-build`, and `make os-build` inside pi-box; verify each succeeds and review any workspace diff for unintended changes.
- [ ] 3.3 Run `make update` in a disposable copy of the worktree; verify the lockfile update succeeds there and leaves the original worktree's `flake.lock` unchanged.

## Workflow follow-up

- Reclaim host disk space before finishing 3.2/3.3: the private `/nix` volume duplicates a closure the host store already holds (about 9 GB here) and the host filesystem is at 100%. `make clean` is human-only, so a human has to free space, or drop the volume with `docker volume rm pi-nix-configs-nix`.
- `make format` passes inside pi-box; `make home-build` built 95 derivations with Nix sandboxing enabled before failing with `No space left on device`, so it needs a re-run once space is available. `make os-build` has not run yet.
- Archive the change once 3.2 and 3.3 are verified.
