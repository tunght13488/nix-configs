## 1. Update flake input

- [ ] 1.1 Change herdr URL ref from `v0.7.3` to `v0.7.4` in `flake.nix`
- [ ] 1.2 Run `nix flake lock --update-input herdr` to pin the new revision

## 2. Update spec

- [ ] 2.1 Apply the delta spec: update version strings from `v0.7.3` to `v0.7.4` in `openspec/specs/herdr-terminal-multiplexer/spec.md`

## 3. Verify

- [ ] 3.1 Run `make home-build` to confirm the updated herdr package builds
- [ ] 3.2 Run `make format` and commit all changes
