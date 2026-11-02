# Tasks

## 1. Refresh the stable inputs

- [ ] 1.1 Selectively refresh the `nixpkgs` and `home-manager` lock revisions on their existing 26.05 branches; review `git diff -- flake.nix flake.lock` to confirm the branch URLs and Home Manager `nixpkgs.follows` are unchanged, and the 25.11 compatibility input, unstable input, Nixvim, and state-version settings were not changed.

## 2. Verify both configurations

- [ ] 2.1 Run `make os-build` and confirm the NixOS configuration builds successfully from the updated lockfile.
- [ ] 2.2 Run `make home-build` and confirm the Home Manager configuration builds successfully from the updated lockfile; do not activate either configuration.
