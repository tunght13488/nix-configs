# Tasks

## 1. Update and verify the sandbox Pi release

- [x] 1.1 Set `piVersion` in `home-manager/pi-sandbox.nix` to `1.5.2`, format the file with `nixpkgs-fmt home-manager/pi-sandbox.nix`, and run `make home-build` to verify the Home Manager configuration builds.
- [x] 1.2 After Home Manager is applied, run `pi-box --version` in a directory without `Dockerfile.pi` and verify the shared image reports `1.5.2`; also verify a project image that does not replace Pi inherits `1.5.2`.
