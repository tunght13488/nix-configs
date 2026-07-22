## 1. Update flake input

- [ ] 1.1 Change `inputs.herdr.url` from `v0.7.4` to `v0.7.5` in `flake.nix`
- [ ] 1.2 Run `nix flake lock --update-input herdr` to regenerate `flake.lock`
- [ ] 1.3 Run `nix flake check --no-write-lock-file` to validate flake evaluation

## 2. Verify build

- [ ] 2.1 Run `make home-build` to verify home-manager configuration evaluates with the new herdr version
- [ ] 2.2 Confirm no unknown config key warnings (the v0.7.5 `herdr config check` is stricter)

## 3. Verify agent skill files

- [ ] 3.1 Confirm `pkgs.herdrAgentFiles` derivation still builds (it sources SKILL.md from the new flake input)
- [ ] 3.2 Spot-check that the bundled SKILL.md exists at the expected path in the v0.7.5 source
