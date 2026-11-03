# Tasks

## 1. Pin Pi 1.5.0

- [x] 1.1 Set `piVersion` in `home-manager/pi-sandbox.nix` to `1.5.0`, keeping the existing substitution and Docker build-argument flow; verify with `rg -n 'piVersion = "1\.5\.0"' home-manager/pi-sandbox.nix`.
- [x] 1.2 Format the Nix module with `nixpkgs-fmt home-manager/pi-sandbox.nix` and run `make home-build`; confirm both commands succeed.

## 2. Verify the sandbox runtime

- [x] 2.1 After Home Manager is applied, run `pi-box --version`; verify the base image rebuild succeeds and reports `1.5.0`. Also verify a representative project image that does not replace Pi inherits version `1.5.0`.
- [x] 2.2 Smoke-test configured custom Pi tool extensions against the 1.5.0 tool-argument validation change; identify any reliance on TypeBox-only schema features without changing user-managed extension files as part of this repository change.
