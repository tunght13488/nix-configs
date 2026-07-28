# Postman App

## Purpose

Document the sourcing, version tracking, and integration contract for the Postman desktop API client within the NixOS + home-manager configuration. Postman is provided via `pkgs.unstable` (the `nixpkgs-unstable` flake input) with an `overrideAttrs` pin in the `unstable-packages` overlay to the latest upstream Postman release, because the nixpkgs `postman` package lags upstream by a full major version.

## Requirements

### Requirement: Postman is sourced from the nixpkgs-unstable input

The home-manager configuration SHALL provide Postman from the `pkgs.unstable` overlay (the `nixpkgs-unstable` flake input) using the flat top-level attribute `unstable.postman`, and SHALL NOT source it from the `nixos-25.11` (`nixpkgs`) input. This preserves the existing `unstable.*` convention already established in `home-manager/home.nix` (shared with `unstable.jetbrains-toolbox`, `unstable.zed-editor`, `unstable.uv`, `unstable.openspec`).

#### Scenario: Package entry resolves to the unstable input

- **WHEN** the home-manager configuration is evaluated (`make home-build`)
- **THEN** the `postman` entry in `home-manager/home.nix` `home.packages` is `unstable.postman`
- **THEN** evaluation succeeds without referencing the `nixos-25.11` `postman` attribute for this package

### Requirement: `unstable.postman` is pinned to the latest upstream Postman release via the unstable-packages overlay

Because the nixpkgs `postman` package lags upstream by a full major version (nixpkgs pins `11.94.0` while upstream Postman desktop ships `12.20.4`, with no nixpkgs PR targeting 12.x), the `unstable-packages` overlay in `overlays/default.nix` SHALL repin `unstable.postman` to the latest upstream Postman desktop version by overriding the derivation's `version` and `src` via `overrideAttrs`, reusing the nixpkgs build/wrap logic underneath. The override SHALL live inside the existing `.extend (...)` block of the `unstable-packages` overlay (alongside the existing `openspec` override precedent). `home-manager/home.nix` SHALL remain unchanged and continue to reference `unstable.postman`, so the override takes effect transparently.

#### Scenario: The unstable postman derivation reports the pinned upstream version

- **WHEN** the `unstable-packages` overlay is evaluated
- **THEN** `prev'.postman` is overridden via `overrideAttrs` to set `version` and `src`
- **THEN** `nix eval --raw '.#nixosConfigurations.nixos-vmware.pkgs.unstable.postman.version'` resolves to the pinned upstream version (12.20.4), not the nixpkgs `11.94.0`

#### Scenario: The source is fetched from the upstream versioned download endpoint

- **WHEN** the pinned `unstable.postman` derivation is built on x86_64-linux
- **THEN** its `src` is a `fetchurl` against `https://dl.pstmn.io/download/version/<pinned-version>/linux64` with the matching SRI hash
- **THEN** the fetched artifact is the upstream Postman Linux64 tarball for the pinned version

#### Scenario: The home-manager build produces the pinned postman store path

- **WHEN** `make home-build` is run after the override is added
- **THEN** the build succeeds and the postman store path version matches the pinned upstream version (12.20.4)

#### Scenario: No change to the home-manager package entry is required

- **WHEN** the override is added in `overlays/default.nix`
- **THEN** `home-manager/home.nix` is byte-identical to the prior commit (it already references `unstable.postman`)

### Requirement: The version pin requires no flake input change

The version pin SHALL be delivered entirely through the `unstable-packages` overlay; `flake.lock` SHALL remain unchanged by this change (`nixpkgs-unstable` and all other input nodes byte-identical to the prior commit), because the override fetches the upstream binary via a fixed-output `fetchurl` independent of the nixpkgs `postman` package's declared version. Other `unstable.*` consumers (`zed-editor`, `uv`, `openspec`, `jetbrains-toolbox`) SHALL be unaffected.

#### Scenario: Only overlays/default.nix changes

- **WHEN** `git diff` is reviewed after the change
- **THEN** the only modified file is `overlays/default.nix` (within the `unstable-packages` overlay's `.extend` block)
- **THEN** `flake.lock` and all input nodes — `nixpkgs`, `nixpkgs-unstable`, `home-manager`, `nixvim`, `agenix`, `nix-index-database`, `phps` — are byte-identical to the prior commit

#### Scenario: Other unstable consumers are unaffected

- **WHEN** the override is in place and `make home-build` is run
- **THEN** `unstable.zed-editor`, `unstable.uv`, `unstable.openspec`, and `unstable.jetbrains-toolbox` resolve to the same derivations as before the change (only `unstable.postman` is overridden)
