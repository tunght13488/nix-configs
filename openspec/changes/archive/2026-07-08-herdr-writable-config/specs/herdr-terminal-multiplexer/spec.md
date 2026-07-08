## MODIFIED Requirements

### Requirement: Herdr config.toml is declaratively managed by home-manager

The system SHALL generate the herdr config baseline from a Nix attrset using `pkgs.formats.toml` and SHALL copy it as a writable real file to `~/.config/herdr/config.toml` via `home.activation` on first activation only, so the config is bootstrapped from version-controlled settings but editable between switches for rapid iteration.

#### Scenario: Config file is a real file copied from the Nix store on first activation

- **WHEN** the user runs `home-manager switch` for the first time and `~/.config/herdr/config.toml` does not exist
- **THEN** the activation script creates `~/.config/herdr/config.toml` as a real file (not a symlink)
- **THEN** the file content matches the Nix-generated TOML from the attrset in `herdr.nix`

#### Scenario: Config file is left untouched on subsequent switches

- **WHEN** the user has edited `~/.config/herdr/config.toml` and runs `home-manager switch`
- **THEN** the activation script detects the file exists and is not a symlink
- **THEN** the file is NOT overwritten — user edits are preserved

#### Scenario: Legacy symlink is replaced with real file

- **WHEN** `~/.config/herdr/config.toml` exists as a symlink (e.g., from a prior `xdg.configFile` deployment)
- **THEN** the activation script copies the Nix-generated TOML over it, replacing the symlink with a real file

#### Scenario: Config is valid TOML

- **WHEN** home-manager evaluates the config derivation
- **THEN** the output is syntactically valid TOML that herdr can parse without errors
