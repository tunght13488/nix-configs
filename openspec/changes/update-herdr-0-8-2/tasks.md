## 1. Flake Input Bump

- [ ] 1.1 Update `inputs.herdr.url` in `flake.nix` from `github:herdrdev/herdr/v0.8.0` to `github:herdrdev/herdr/v0.8.2`
- [ ] 1.2 Run `nix flake lock --update-input herdr` to regenerate the `flake.lock` entry

## 2. Build and Compatibility Verification

- [ ] 2.1 Run `make home-build` to confirm the herdr package and the `herdrAgentFiles` derivation build against v0.8.2
- [ ] 2.2 Validate the config baseline against the v0.8.2 binary: build the config from `home-manager/herdr.nix` and run `herdr config check` on it, confirming `one-dark` is still accepted as a built-in theme name
- [ ] 2.3 If `herdr config check` reports an unknown or retired key, apply a minimal compatibility fix to the baseline in `home-manager/herdr.nix` and repeat 2.1–2.2
- [ ] 2.4 Confirm the skill output still contains both files: `nix build .#herdrAgentFiles` (or inspect the built path) and verify `.pi/skills/herdr/SKILL.md` and `.opencode/skills/herdr/SKILL.md` exist

## 3. Apply and Final Check

- [ ] 3.1 Run `home-manager switch` (user step — requires terminal) so the writable config bootstrap and skill symlinks activate
- [ ] 3.2 After switch, run `herdr --version` to confirm v0.8.2 is on PATH and `herdr config check` passes on the live `~/.config/herdr/config.toml`
