## Why

The herdr config is symlinked from the read-only Nix store, making it impossible to edit live and test settings via `herdr server reload-config`. Iterating on herdr configuration currently requires editing the Nix attrset, running `home-manager switch`, and restarting herdr — too slow for exploration. The config should be a writable file bootstrapped from the Nix baseline.

## What Changes

- Replace `xdg.configFile` symlink with a `home.activation` script that copies the generated TOML on first activation only
- The Nix attrset in `herdr.nix` remains the single source of truth for the baseline
- The live file at `~/.config/herdr/config.toml` becomes a real file (not a symlink), editable between switches
- Subsequent `home-manager switch` runs leave the live file untouched (it's a real file, not a symlink)
- Reset is manual: back up then `rm ~/.config/herdr/config.toml` before switching

## Capabilities

### New Capabilities

None — this is a deployment pattern change, not a new feature.

### Modified Capabilities

- `herdr-terminal-multiplexer`: The config file requirement changes from "symlink to Nix store" to "writable file copied from Nix store on first activation." The attrset-based configuration and TOML generation remain unchanged; only the deployment mechanism changes.

## Impact

- Affected file: `home-manager/herdr.nix`
- No changes to the Nix attrset, TOML generation, or herdr package
- No impact on other modules or configs
- User must `cp` backup before `rm` + `switch` to reset (documented in module comment)
