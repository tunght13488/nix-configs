## ADDED Requirements

### Requirement: Herdr config.toml is declaratively managed by home-manager

The system SHALL generate `~/.config/herdr/config.toml` from a Nix attrset using `pkgs.formats.toml` and SHALL place it via `xdg.configFile` so that the config is reproducible and version-controlled.

#### Scenario: Config file is a symlink to the Nix store

- **WHEN** the user runs `home-manager switch`
- **THEN** `~/.config/herdr/config.toml` is a symlink to a TOML file in the Nix store
- **THEN** the generated TOML contains at minimum: `onboarding = false`, `[keys] prefix = "ctrl+b"`, and `[theme] name = "one-dark"`

#### Scenario: Config is valid TOML

- **WHEN** home-manager evaluates the config derivation
- **THEN** the output is syntactically valid TOML that herdr can parse without errors

### Requirement: Herdr config module follows existing file conventions

The system SHALL place the herdr home-manager configuration in `home-manager/herdr.nix` and SHALL import it from `home-manager/home.nix` alongside the existing tool configs.

#### Scenario: herdr.nix is imported in home.nix

- **WHEN** home-manager evaluates `home.nix`
- **THEN** `./herdr.nix` is present in the `imports` list
- **THEN** the herdr config file is generated as part of the home-manager activation

### Requirement: Tmux configuration is unchanged

The system SHALL NOT modify any tmux-related configuration. The herdr prefix (`ctrl+b`) SHALL differ from the tmux prefix (`` ` ``) to allow both multiplexers to run simultaneously without keybinding conflicts.

#### Scenario: tmux.nix remains intact

- **WHEN** `herdr.nix` is added and imported
- **THEN** `home-manager/tmux.nix` is unchanged
- **THEN** tmux continues to use `` ` `` as its prefix
- **THEN** herdr uses `ctrl+b` as its prefix, avoiding collisions when herdr runs inside a tmux pane
