# Proposal

## Why

Refresh the pinned revisions of the stable NixOS and Home Manager inputs to pick up current fixes and package updates while staying on the existing 26.05 release lines. The 26.11 release is not stable yet, so this change must not advance either branch.

The refreshed nixpkgs adds a `filter` extension patch for PHP 8.2+, unguarded for older runtimes, so PHP 8.1 from the `phps` overlay no longer builds. No remaining project needs PHP 8.1 (all are on 8.2, moving to 8.3), so 8.1 is removed instead of worked around.

## What Changes

- Update the lockfile revisions for `nixpkgs` (`nixos-26.05`) and `home-manager` (`release-26.05`), preserving their declared release branches and the Home Manager `nixpkgs.follows` relationship.
- Remove PHP 8.1 from the stack: the FPM pool, nginx virtual host, test site, versioned CLI wrappers, per-version INI defaults, and the `php81` zlib/zip overlay override.
- Leave `nixpkgs-2511`, `nixpkgs-unstable`, Nixvim, and other unrelated inputs unchanged.
- Keep `system.stateVersion` and `home.stateVersion` unchanged; this is a flake-input refresh, not a state migration.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is dependency and lockfile maintenance with no new spec-level behavior; `.openspec.yaml` sets `skip_specs: true`.

## Impact

- `flake.lock` and the evaluated NixOS and Home Manager configurations that consume the refreshed inputs.
- PHP 8.1 removal touches `nixos/configuration.nix`, `nixos/php-fpm.nix`, `nixos/nginx.nix`, `nixos/vhosts/php81.vm.local.nix`, `home-manager/php.nix`, `pkgs/php-config.nix`, `overlays/default.nix`, and the PHP version references in the repo docs.
- `https://php81.local` and `php81`/`composer81` binaries disappear; `php82` and `php83` are unchanged.
- Validate both configurations with `make os-build` and `make home-build`; do not activate either configuration as part of this change.
