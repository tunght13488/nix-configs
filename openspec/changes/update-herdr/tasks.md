## 1. Update flake input

- [ ] 1.1 Change herdr URL ref from `v0.7.1` to `v0.7.3` in `flake.nix`
- [ ] 1.2 Run `nix flake lock --update-input herdr` to pin the new revision

## 2. Verify

- [ ] 2.1 Run `make home-build` to confirm the updated herdr package builds
- [ ] 2.2 Run `make format` and commit all changes
