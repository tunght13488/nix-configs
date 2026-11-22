# Tasks

## 1. Package herdr-core

- [ ] 1.1 Create `pkgs/herdr-core.nix` per design.md: `fetchFromGitHub` pinned to the v0.1.21 commit with `fetchSubmodules = true`, `rustPlatform.buildRustPackage` with `cargoLock` from the fetched `Cargo.lock`, `zig_0_16` with `ZIG` env, `zig_0_16.fetchDeps` on `vendor/ghostty` with `ZIG_GLOBAL_CACHE_DIR`, `postInstall` symlinking `hc` to `herdr-core`, `doCheck = false`, and an update-steps header comment (obsidian.nix style). `git add` the file. Verify: the file exists and is tracked in git.
- [ ] 1.2 Add `herdr-core = pkgs.callPackage ./herdr-core.nix { };` to `pkgs/default.nix` and `git add` it. Verify: `nix eval .#herdr-core.meta.mainProgram` evaluates without errors.
- [ ] 1.3 Fill in `cargoHash` and the `fetchDeps` hash from the first build errors (`lib.fakeHash`), then rebuild until the hashes match. Verify: `nix build .#herdr-core` completes and performs no network fetches during the build phase.
- [ ] 1.4 Smoke-test the build result. Verify: `result/bin/hc --help` exits 0 and lists the core commands, `result/bin/hc --version` reports the pinned version, and `result/bin/herdr-core` exists with `hc` as a symlink to it.

## 2. Refresh the herdr input

- [ ] 2.1 Check the latest stable release (`curl -s https://api.github.com/repos/herdrdev/herdr/releases/latest`); if a release newer than v0.9.5 exists, update `inputs.herdr.url` in `flake.nix` to that tag. Verify: the flake input tag matches the latest stable release at implementation time.
- [ ] 2.2 Run `nix flake update herdr`. Verify: the lock now points at the pinned tag's current commit and a second `nix flake update herdr` reports no change.

## 3. Install and integrate

- [ ] 3.1 Add `herdr-core` to `home.packages` in `home-manager/home.nix` next to the existing `herdr` entry and `git add` the file. Verify: `make home-build` completes without evaluation errors.
- [ ] 3.2 Inspect the built home-manager generation. Verify: the PATH includes both `hc` and `herdr`, and `home-manager/herdr.nix` config bootstrap and skill symlinks are unchanged in the activation script.
- [ ] 3.3 Run `make format` and re-run `make home-build`. Verify: both pass and no non-`.nix` file was reformatted.

## 4. Validate end to end after activation

- [ ] 4.1 After the user runs `make home`, verify `command -v hc`, `hc --help` exits 0, and `hc --version` reports the pinned version.
- [ ] 4.2 Verify coexistence: `herdr` still launches, and `~/.config/herdr/config.toml` and the agent skill symlinks remain intact after activation.

## Workflow follow-up

- Archive the change after the project's review requirements are satisfied.
