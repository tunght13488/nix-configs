# Design

## Context

- Custom packages live in `pkgs/` and are exposed two ways: flake packages (`nix build .#<name>`, via `import ./pkgs nixpkgs.legacyPackages.<system>` in `flake.nix`) and the `additions` overlay (`pkgs.<name>`). Pinned upstream sources use `fetchFromGitHub` inside the package file, e.g. `pkgs/obsidian.nix` and `pkgs/jetbrains-toolbox.nix`, with update steps recorded in the file header.
- The herdr-core upstream repo has **no flake.nix**. It is a Rust workspace (edition 2024) with `crates/herdr-core` (binary `herdr-core`, upstream installs it with an `hc` symlink) and `crates/ghostty-vt`, whose `build.rs` runs `zig build -Demit-lib-vt -Doptimize=ReleaseFast -Dcpu=baseline` inside the `vendor/ghostty` git submodule and requires Zig 0.16 (`ZIG` env var).
- Verified empirically: flake `github:` inputs do **not** fetch git submodules — fetching `github:herdrdev/herdr-core/v0.1.21` as a `flake = false` input leaves `vendor/ghostty` empty. `fetchFromGitHub { fetchSubmodules = true; }` is required.
- nixpkgs 26.05 provides `zig_0_16` (0.16.0) and `zig_0_16.fetchDeps` (`pkgs/development/compilers/zig/fetcher.nix`), which runs `zig build --fetch` in a given source and captures the Zig package-manager global cache (`p/`) as a store path.
- The herdr input is pinned to v0.9.5, the latest stable release (verified at implementation time: no newer tag, and the locked rev `2ecf19a` is the tag's commit, so `nix flake update herdr` is a no-op).

## Goals / Non-Goals

**Goals:**

- Build `herdr-core` hermetically on x86_64-linux from the pinned upstream source, with `hc` on PATH.
- Confirm the herdr input is at the latest stable release tag.

**Non-Goals:**

- No global agent-skill symlinks for `hc` — `hc --skill` prints its own agent docs.
- No `~/.config/herdr-core/config.toml` bootstrap; `hc` works with defaults.
- No replacement of the herdr TUI, no NixOS-level changes, no pi-box sandbox changes.

## Decisions

### 1. Source: `fetchFromGitHub` with submodules inside the package, no flake input

`pkgs/herdr-core.nix` pins `owner = "herdrdev"; repo = "herdr-core"; rev = "<v0.1.21 commit>"; fetchSubmodules = true; hash = "<sha256>";`.

- **Why**: upstream has no flake.nix, and flake git inputs skip submodules (verified above). One pin, one hash, no drift. Matches the repo's pinned-source package pattern.
- **Alternative considered**: flake input (`flake = false`) plus a separately pinned ghostty fetch — two pins that can silently diverge; rejected.

### 2. Package derivation modeled on herdr's own `nix/package.nix`, plus the nixpkgs Zig fetcher

- `rustPlatform.buildRustPackage` with `cargoLock.lockFile = "${src}/Cargo.lock"` (the fetched source carries it), `version = "0.1.21"`.
- `nativeBuildInputs = [ zig_0_16 pkg-config ]`; `env.ZIG = lib.getExe zig_0_16`.
- Zig dependencies: `zigDeps = zig_0_16.fetchDeps { pname = "herdr-core-ghostty"; version = "0.1.21"; src = "${src}/vendor/ghostty"; fetchAll = false; hash = ...; }` and `ZIG_GLOBAL_CACHE_DIR = zigDeps` (its output is the `p/` directory). herdr-core's `build.rs` passes only `--cache-dir` into `OUT_DIR`, so Zig resolves packages from the global cache — no network.
- `postInstall`: `ln -s herdr-core $out/bin/hc`, mirroring upstream `install.sh`, which installs `herdr-core` and symlinks `hc` to it.
- `doCheck = false`, mirroring the herdr package's build-only check rationale.
- **Why**: herdr-core's `ghostty-vt` build.rs lacks herdr's `LIBGHOSTTY_VT_ZIG_SYSTEM_DIR` escape hatch, so herdr's linkFarm approach does not apply; `fetchDeps` is the nixpkgs-native way to make `zig build` sandbox-safe.
- **Alternative considered**: replicate `vendor/libghostty-vt/build.zig.zon.nix` linkFarm generation and hand-place hashes into the cache — more moving parts for the same result; rejected.

### 3. Exposure via `pkgs/default.nix`

Add `herdr-core = pkgs.callPackage ./herdr-core.nix { };` to `pkgs/default.nix`. This automatically provides both `nix build .#herdr-core` and `pkgs.herdr-core` through the additions overlay; no `overlays/default.nix` edit needed.

### 4. Home-manager install next to the herdr binary

Add `herdr-core` to `home.packages` in `home-manager/home.nix` next to the existing `herdr` entry. `home-manager/herdr.nix` (config bootstrap, skill links) stays untouched.

### 5. Herdr update via `nix flake update herdr`

Run `nix flake update herdr` and check the GitHub latest release at implementation time; if a stable release newer than v0.9.5 exists, bump `inputs.herdr.url` to it and re-run the update. Implemented as a verification: v0.9.5 was still latest and the lock already held its commit, so the update reported no change.

## Risks / Trade-offs

- [fetchSubmodules pulls the full ghostty repo] → one-time source fetch, pinned by rev and hash; no re-fetch on rebuilds.
- [Zig 0.16 may not honor `ZIG_GLOBAL_CACHE_DIR` for the local `--cache-dir` build] → verify during the first build; fallback is copying the `p/` contents into the cache layout Zig expects, or the linkFarm approach.
- [Workspace-wide cargo build] → building both workspace members is expected (ghostty-vt is a dependency); if it fails, set `cargoBuildFlags = [ "-p" "herdr-core" ]`.
- [Newer herdr release landing mid-change] → the MODIFIED requirement already targets "latest stable"; re-check the tag at implementation time.
- [`hc` and the herdr TUI are independent runtimes] → they coexist; `hc` uses a separate `~/.config/herdr-core/` config dir and does not touch herdr's state.

## Migration Plan

- Build and evaluate: `nix build .#herdr-core`, then `make home-build`; the user runs `make home` to activate (repo policy: activation targets are human-run).
- Rollback: the change is additive; reverting to the previous home-manager generation removes `hc` and restores the prior herdr lock.

## Open Questions

- None blocking. If upstream later ships a flake.nix for herdr-core, the pinning decision can be revisited then.
