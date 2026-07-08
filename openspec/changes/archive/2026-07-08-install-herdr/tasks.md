## 1. Flake Input

- [x] 1.1 Add `herdr.url = "github:ogulcancelik/herdr/v0.7.1";` to flake inputs in `flake.nix`
- [x] 1.2 Add `herdr` to the outputs function argument destructuring (appears automatically in `...`)

## 2. Home-Manager Integration

- [x] 2.1 Add `herdr.overlays.default` to the overlays list in `homeConfigurations."tung@nixos-vmware".pkgs` in `flake.nix`
- [x] 2.2 Add `herdr` to `home.packages` list in `home-manager/home.nix`

## 3. Verification

- [x] 3.1 Run `make home-build` to verify the flake evaluates and herdr builds successfully
- [x] 3.2 `git add` new/changed files and verify `nix flake check --no-write-lock-file` passes
