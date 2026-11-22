# Tasks

## 1. Package herdr-core

- [x] 1.1 Create `pkgs/herdr-core.nix` per design.md: `fetchFromGitHub` pinned to the v0.1.21 commit with `fetchSubmodules = true`, `rustPlatform.buildRustPackage` with `cargoLock` from the fetched `Cargo.lock`, `zig_0_16` with `ZIG` env, `zig_0_16.fetchDeps` on `vendor/ghostty` with `ZIG_GLOBAL_CACHE_DIR`, `postInstall` symlinking `hc` to `herdr-core`, `doCheck = false`, and an update-steps header comment (obsidian.nix style). `git add` the file. Verify: the file exists and is tracked in git.
- [x] 1.2 Add `herdr-core = pkgs.callPackage ./herdr-core.nix { };` to `pkgs/default.nix` and `git add` it. Verify: `nix eval .#herdr-core.meta.mainProgram` evaluates without errors.
- [x] 1.3 Fill in the `src` and `zigDeps` hashes from the first build errors (`lib.fakeHash`), then rebuild until they match. Corrected during implementation: no `cargoHash` is needed because `cargoLock.lockFile` derives the vendor dir from the fetched `Cargo.lock`; `zig_0_16` is passed only via the `ZIG` env var because adding it to `nativeBuildInputs` lets zig's setup hook replace `buildPhase` with `zig build` in the source root. Verify: `nix build .#herdr-core` completes in the sandbox, so no build-phase network fetch was needed.
- [x] 1.4 Smoke-test the build result. Verify: `result/bin/hc --help` exits 0 and lists the core commands, `result/bin/hc --version` reports the pinned version, and `result/bin/herdr-core` exists with `hc` as a symlink to it.

## 2. Refresh the herdr input

- [x] 2.1 Check the latest stable release (`curl -s https://api.github.com/repos/herdrdev/herdr/releases/latest`); if a release newer than v0.9.5 exists, update `inputs.herdr.url` in `flake.nix` to that tag. Result: v0.9.5 is still the latest, so `flake.nix` is unchanged.
- [x] 2.2 Run `nix flake update herdr`. Result: no change — the locked rev `2ecf19a` is already the commit behind the annotated tag `v0.9.5` (its tag object is `7573e82`), so the lock was current and the update reports no change.

## 3. Install and integrate

- [x] 3.1 Add `herdr-core` to `home.packages` in `home-manager/home.nix` and `git add` the file. Verified: `make home-build` succeeds and the generation adds `herdr-core 0.1.21` (+8.47 MiB).
- [x] 3.2 Inspect the built home-manager generation. Verified: `home-path/bin/hc` points at `herdr-core-0.1.21` and `home-path/bin/herdr` at `herdr-0.9.5`; `activate` still runs the `copyHerdrConfig` step, and the `.pi`/opencode herdr skill symlinks are still deployed.
- [x] 3.3 Run `make format` and re-run `make home-build`. Verified: both pass; `make format` reformatted no tracked file, and the rebuild still succeeds.

## 4. Validate end to end after activation

- [ ] 4.1 After the user runs `make home`, verify `command -v hc`, `hc --help` exits 0, and `hc --version` reports the pinned version.
- [ ] 4.2 Verify coexistence: `herdr` still launches, and `~/.config/herdr/config.toml` and the agent skill symlinks remain intact after activation.

## Workflow follow-up

- Archive the change after the project's review requirements are satisfied.
