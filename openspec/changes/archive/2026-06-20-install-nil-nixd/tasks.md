## 1. Home Manager Package Installation

- [x] 1.1 Add `pkgs.nil` and `pkgs.nixd` to `home.packages` in `home-manager/home.nix`
- [x] 1.2 Run `make home-build` to verify the configuration evaluates and builds successfully
- [x] 1.3 Confirm `nil --version` and `nixd --version` are available in the built environment

## 2. Verification

- [x] 2.1 Run `nix flake check --no-write-lock-file` to validate the flake
- [x] 2.2 Confirm no formatting issues with `make format`
