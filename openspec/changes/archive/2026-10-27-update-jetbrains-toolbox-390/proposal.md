# Proposal

## Why

`make home-build` cannot build `jetbrains-toolbox` from a store that does not already have it cached. The package fetched by the pinned `nixpkgs-unstable` revision is 3.6.2.85969 from `download-cdn.jetbrains.com`, and that host now returns HTTP 404 for it (only its `.sha256` still resolves). JetBrains moved Linux releases to `download.jetbrains.com`, and nixpkgs followed: current `nixos-unstable` (3.8.1.88030) and `master` (3.9.0.88839) both fetch from the working host. So the failure is a stale download host plus a stale version, not a transient outage.

Latest upstream is 3.9.0.88839 (2026-10-19), which exists only on nixpkgs `master`, not on `nixos-unstable`.

## What Changes

- Pin `jetbrains-toolbox` to 3.9.0.88839 from `download.jetbrains.com` with a repo-owned derivation in `pkgs/jetbrains-toolbox.nix`, mirroring the existing `postman` override precedent.
- Wire it into the `unstable-packages` overlay so `unstable.jetbrains-toolbox` still names the package; `home-manager/home.nix` does not change.
- Leave `flake.lock` untouched: the bump is delivered by the overlay, not by advancing the `nixpkgs-unstable` input.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `jetbrains-toolbox`: the package's derivation now comes from the repository's pinned definition at 3.9.0.88839 with a working download host, and the version/lockfile expectations change accordingly.

## Impact

- Adds `pkgs/jetbrains-toolbox.nix` and one entry in `overlays/default.nix` (`unstable-packages`).
- `home-manager/home.nix` is unchanged; the package attribute name stays `unstable.jetbrains-toolbox`.
- Restores `make home-build` (and in-sandbox builds) for any store without a cached Toolbox, which unblocks the `add-nix-configs-pi-box-template` verification.
