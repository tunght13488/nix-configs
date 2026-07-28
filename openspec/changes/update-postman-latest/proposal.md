## Why

Postman in `home-manager/home.nix` is already sourced via `unstable.postman`, but the nixpkgs `postman` package is stuck at **11.94.0** on both the pinned `nixpkgs-unstable` input (rev `624af66`, bumped 2026-07-27) and the `nixos-unstable` HEAD (no nixpkgs PR targets a 12.x bump). Upstream Postman desktop is at **12.20.4** (2026-07-25) — a full major version ahead — and the gap will not close from merely bumping the flake lock, because the nixpkgs package itself lags. To run a current Postman on this machine while staying on the unstable channel, the `postman` derivation must be pinned to the latest upstream release explicitly.

## What Changes

- Add a `postman` override inside the existing `unstable-packages` overlay (`overlays/default.nix`), mirroring the established `openspec` `overrideAttrs` precedent already present in the same `.extend (...)` block. The override pins `unstable.postman` to the latest upstream Postman desktop version (12.20.4) by overriding `version` and `src` (fetchurl against `https://dl.pstmn.io/download/version/<ver>/<system>`), keeping the nixpkgs build/wrap logic underneath.
- No change to `home-manager/home.nix` — it already references `unstable.postman`, so the override takes effect transparently.
- **No `flake.lock` change** — the override fetches the upstream binary directly, so the existing one-day-old `nixpkgs-unstable` rev is sufficient. The 25.11 release-branch inputs stay untouched (matches the repo's targeted-change discipline).
- Accepts an ongoing maintenance cost: each new Postman upstream release requires re-pinning the version + re-hashing the source in the overlay. This is the explicit tradeoff of choosing an upstream pin over waiting for nixpkgs to ship 12.x.

## Capabilities

### New Capabilities
- `postman-app`: Sourcing and version-tracking contract for the Postman desktop API client — sourced from `pkgs.unstable.postman` and pinned to the latest upstream Postman release via an `overrideAttrs` override in the `unstable-packages` overlay, because the nixpkgs `postman` package lags upstream by a major version.

### Modified Capabilities
<!-- None. No prior spec for `postman-app` exists in openspec/specs/. -->

## Impact

- **Code**: `overlays/default.nix` — new `postman = prev'.postman.overrideAttrs ...` entry inside the `unstable-packages` overlay's `.extend (...)` block (alongside the existing `openspec` override). No other code touched.
- **Dependencies**: No flake input changes; `flake.lock` unchanged. The override adds a fixed-output fetchurl of the upstream Postman Linux64 tarball (~160 MB) sourced from `dl.pstmn.io`.
- **Systems**: The home-manager build (`make home-build`) is the verification path. No NixOS system change, no new services, no secrets.
- **Runtime**: After apply, `unstable.postman.version` evaluates to the pinned upstream version (12.20.4) and the store path builds; launching Postman runs 12.20.4.
- **Scope**: Only Postman. Other `unstable.*` consumers (`zed-editor`, `uv`, `openspec`, `jetbrains-toolbox`) are unaffected.
- **Known limitations**: x86_64-linux only — the flake targets a single machine (`nixos-vmware`), so the override fills only the `linux64` source hash. The override also rides on the underlying `unstable.postman` build/wrap logic staying structurally compatible, so future `nixpkgs-unstable` bumps could require the override to be updated; detectable at `make home-build`.