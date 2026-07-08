## 1. Create herdr config module

- [ ] 1.1 Create `home-manager/herdr.nix` with `xdg.configFile` using `pkgs.formats.toml` to generate `herdr/config.toml`
- [ ] 1.2 Seed the config with existing preferences: `onboarding = false`, `theme.name = "one-dark"`, `theme.auto_switch = false`
- [ ] 1.3 Set `keys.prefix = "ctrl+b"` explicitly (coexists with tmux's `` ` `` prefix)

## 2. Wire up imports

- [ ] 2.1 Add `./herdr.nix` to the `imports` list in `home-manager/home.nix`

## 3. Verify

- [ ] 3.1 Run `make home-build` and confirm no evaluation errors
- [ ] 3.2 Inspect generated TOML by building the derivation: `nix build .#homeManagerConfigurations.tung.conf.path --no-link --print-out-paths` and reading the output file
