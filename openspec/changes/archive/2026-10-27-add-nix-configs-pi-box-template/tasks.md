# Tasks

## 1. Add the Nix-configs template

- [x] 1.1 Add `home-manager/pi-box-templates/nix-configs/Dockerfile.pi` and `pi-box.toml` with the flake-capable Nix toolchain, existing OpenSpec CLI pin, and named `/nix` volume; force-add both scaffold-named files and verify they are tracked.
- [x] 1.2 Build the project image and verify `make`, `nix`, `nh`, `nixos-rebuild`, `nixpkgs-fmt`, and `openspec` are available and Nix has `nix-command` and `flakes` enabled.
- [x] 1.3 Add the `privileged` manifest grant to `home-manager/pi-box.sh` (parser, run arguments, help text) and set it in the template manifest; verify a sandboxed `docker run` argument list contains `--privileged` only when the manifest declares it.
- [x] 1.4 Verify a Nix build completes with sandboxing enabled inside rootless Docker, that a store path persists across two runs of the named volume, and that no host `/nix` path or daemon socket is mounted.
- [x] 1.5 Set `USER`/`LOGNAME` in the template image so `nh` can resolve the invoking user inside the sandbox, and verify `make home-build` no longer ends with "Couldn't get username".
- [x] 1.6 Make `pi-box init` write writable scaffolds: template files come from the read-only Nix store, so the copy needs `chmod u+w`; verify a fresh `init` produces mode `644` files.

## 2. Update project instructions

- [x] 2.1 Update `AGENTS.md` to permit `make format`, `make home-build`, `make os-build`, and `make update`, and reserve `make os`, `make os-boot`, `make home`, `make clean`, and `make os-test` for humans; verify the instructions contain exactly this policy and no Makefile guard is added.
- [x] 2.2 Document the `nix-configs` template, the `privileged` grant and why Nix needs it, `pi-box init --force nix-configs` adoption, and the named-volume cleanup; verify the documented template, grant, and volume names match their files.

## 3. Deploy and verify the workflow

- [x] 3.1 After a human applies Home Manager with `make home`, run `pi-box init --force nix-configs` in this worktree; verify it backs up the existing ignored `Dockerfile.pi` and creates the new project Dockerfile and manifest.
- [x] 3.2 Run `make format`, `make home-build`, and `make os-build` inside pi-box; verify each succeeds and review any workspace diff for unintended changes.
- [x] 3.3 Run `make update` in a disposable copy of the worktree; verify the lockfile update succeeds there and leaves the original worktree's `flake.lock` unchanged.

## Workflow follow-up

- Verification results inside pi-box: `make format` (0 / 50 reformatted), `make home-build` (exit 0, built `jetbrains-toolbox-3.9.0.88839`, herdr, nixvim), `make os-build` (exit 0, produced `nixos-system-nixos-vmware-26.05`), `make update` in a disposable copy (exit 0, this worktree's `flake.lock` byte-identical afterwards).
- Two blockers had to be fixed before `home-build` could pass inside the sandbox: `jetbrains-toolbox` 3.6.2 was fetched from a host that now returns 404 (fixed by the separate `update-jetbrains-toolbox-390` change), and `nh` could not resolve the invoking user because docker leaves `USER`/`LOGNAME` unset (fixed by the template's `ENV USER`/`LOGNAME`).
- The template gained `USER`/`LOGNAME` after the Home Manager generation was applied, so a human needs one more `make home` before `pi-box init nix-configs` produces the updated scaffold for a new worktree.
- The `/nix` volume holds roughly 30 GB after these runs. Drop it with `docker volume rm pi-nix-configs-nix` if the space is needed; the next in-container build re-downloads it.
- Archive the change now that 3.1-3.3 are verified.
