# Herdr Terminal Multiplexer

## Purpose

Provide the `herdr` terminal multiplexer binary on the user's PATH, installed from a pinned flake input alongside the existing tmux setup.

## Requirements

### Requirement: Herdr is available as a home-manager package

The system SHALL make the `herdr` binary available in the user's PATH via home-manager's `home.packages`, installed from a pinned flake input.

#### Scenario: Herdr binary is on PATH after home-manager switch

- **WHEN** the user runs `home-manager switch` with the herdr package included
- **THEN** the `herdr` command is available in the shell PATH
- **THEN** running `herdr` starts the Herdr terminal multiplexer

### Requirement: Herdr is pinned via a flake input

The system SHALL declare herdr as a flake input at `inputs.herdr.url = "github:herdrdev/herdr/v0.8.2"` and SHALL NOT override its nixpkgs input via `follows`.

#### Scenario: Herdr flake input is declared

- **WHEN** the flake is evaluated (`nix flake check` or `nix flake show`)
- **THEN** the `herdr` input resolves to the `github:herdrdev/herdr` repository at tag `v0.8.2`
- **THEN** the herdr package builds from the flake's own `nix/package.nix` using its own nixpkgs

### Requirement: Herdr overlay is applied to home-manager

The system SHALL apply `herdr.overlays.default` in the home-manager nixpkgs configuration so that `pkgs.herdr` resolves to the flake-provided package.

#### Scenario: pkgs.herdr resolves in home-manager context

- **WHEN** home-manager evaluates `pkgs.herdr`
- **THEN** it resolves to the herdr derivation from the pinned flake input

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

### Requirement: Herdr config module follows existing file conventions

The system SHALL place the herdr home-manager configuration in `home-manager/herdr.nix` and SHALL import it from `home-manager/home.nix` alongside the existing tool configs.

#### Scenario: herdr.nix is imported in home.nix

- **WHEN** home-manager evaluates `home.nix`
- **THEN** `./herdr.nix` is present in the `imports` list
- **THEN** the herdr config file is generated as part of the home-manager activation

### Requirement: Existing tmux configuration is unchanged

The system SHALL NOT modify or remove the existing tmux configuration. Herdr SHALL coexist alongside tmux as an independently available binary. The herdr prefix SHALL differ from the tmux prefix to allow both multiplexers to run simultaneously without keybinding conflicts.

#### Scenario: tmux remains installed and configured after adding herdr binary

- **WHEN** herdr is added to `home.packages`
- **THEN** the existing tmux package and its home-manager configuration (`tmux.nix`) remain intact
- **THEN** `tmux` continues to function as before

#### Scenario: tmux.nix remains intact after adding herdr config module

- **WHEN** `herdr.nix` is added and imported in home-manager
- **THEN** `home-manager/tmux.nix` is unchanged
- **THEN** tmux continues to use `` ` `` as its prefix
- **THEN** herdr uses `ctrl+b` as its prefix, avoiding collisions when herdr runs inside a tmux pane
