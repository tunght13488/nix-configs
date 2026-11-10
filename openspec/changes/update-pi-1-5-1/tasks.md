# Tasks

## 1. Update and verify the sandbox Pi release

- [ ] 1.1 Set `piVersion` to `1.5.1` in `home-manager/pi-sandbox.nix` and verify the Home Manager configuration builds with `make home-build`.
- [ ] 1.2 After applying the Home Manager configuration, run `pi-box --version` from a directory without `Dockerfile.pi` and verify the shared sandbox image reports Pi version `1.5.1`.
