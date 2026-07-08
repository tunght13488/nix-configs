## Why

herdr is installed and working, but its `~/.config/herdr/config.toml` was created imperatively and sits outside version control. A declarative configuration managed by home-manager ensures the herdr config is reproducible, version-controlled, and integrated into the same Nix workflow as tmux and other terminal tools.

## What Changes

- Add a new `home-manager/herdr.nix` module that generates `~/.config/herdr/config.toml` using `pkgs.formats.toml`
- Import `herdr.nix` in `home-manager/home.nix`
- Seed the config with the existing preferences (theme, onboarding disabled) plus an explicit `ctrl+b` prefix to avoid collision with tmux's `` ` `` prefix
- Use `xdg.configFile` for placement — the same pattern as `openspec.nix` for tools without a home-manager module

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `herdr-terminal-multiplexer`: Add a requirement for declarative config.toml management via home-manager's `xdg.configFile`, generated from `pkgs.formats.toml`

## Impact

- New file: `home-manager/herdr.nix`
- Modified file: `home-manager/home.nix` (add `./herdr.nix` to imports)
- The existing `~/.config/herdr/config.toml` will become a read-only symlink to the Nix store — the user must migrate any manual tweaks into `herdr.nix` before the next `home-manager switch`
- `herdr config reset-keys` will no longer be able to write to the config file; keybinding changes go through the Nix module
