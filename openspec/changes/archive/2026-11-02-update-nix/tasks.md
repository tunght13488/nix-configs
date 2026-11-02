# Tasks

## 1. Refresh the stable inputs

- [x] 1.1 Selectively refresh the `nixpkgs` and `home-manager` lock revisions on their existing 26.05 branches; review `git diff -- flake.nix flake.lock` to confirm the branch URLs and Home Manager `nixpkgs.follows` are unchanged, and the 25.11 compatibility input, unstable input, Nixvim, and state-version settings were not changed.

## 2. Remove PHP 8.1

- [x] 2.1 Delete the PHP 8.1 system wiring (NixOS packages, FPM pool, systemd service override, nginx vhost file and its list entry) and verify `rg -n 'php81|v81' nixos` returns no hits.
- [x] 2.2 Delete the PHP 8.1 user wiring (test site file, activation chmod path) and the `php81` per-version INI default; verify `rg -n 'php81' home-manager pkgs` returns only generic example comments.
- [x] 2.3 Drop the `php81` zlib/zip override from `overlays/default.nix` and update the PHP version references in the repo docs; verify `rg -n 'php81|PHP 8\.1' --glob '!openspec/**' --glob '!openwiki/**' --glob '!*.lock'` returns no stale runtime or doc claims.

## 3. Verify both configurations

- [x] 3.1 Run `make os-build` and confirm the NixOS configuration builds successfully from the updated lockfile.
- [x] 3.2 Run `make home-build` and confirm the Home Manager configuration builds successfully from the updated lockfile; do not activate either configuration.
