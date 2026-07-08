## Context

herdr is already installed via `home.packages` with a pinned flake input (`github:ogulcancelik/herdr/v0.7.1`). The binary works, but its config file at `~/.config/herdr/config.toml` was created imperatively by running `herdr` for the first time. It contains two settings: theme (`one-dark`) and onboarding disabled. There is no version control or reproducibility for these settings.

The nix-configs repo already uses two patterns for managing config files of tools without home-manager modules:
- **Raw string** (`openspec.nix`): `xdg.configFile."path".text = ''...''` — simple but no validation
- **TOML generation** (`terminal.nix` via alacritty module): the built-in module handles this internally

herdr uses TOML, and `pkgs.formats.toml` is the standard Nixpkgs approach for generating TOML files from Nix attrsets.

## Goals / Non-Goals

**Goals:**
- Manage herdr's `config.toml` declaratively through home-manager
- Use `pkgs.formats.toml` for type-safe TOML generation
- Preserve the user's existing preferences (theme, onboarding state)
- Set an explicit prefix (`ctrl+b`) to document the intentional coexistence with tmux (which uses `` ` ``)
- Follow the existing pattern of importing a dedicated `.nix` file in `home.nix`

**Non-Goals:**
- Creating a reusable home-manager module for herdr (no `modules/home-manager/herdr.nix`)
- Adding all possible herdr config options — start minimal and expand gradually
- Changing tmux configuration in any way

## Decisions

### TOML generation via `pkgs.formats.toml` (not raw string)

`pkgs.formats.toml` converts Nix attrsets to valid TOML. Nested attrsets become `[section]` headers automatically. This provides basic type validation at build time (booleans stay booleans, strings stay strings) without needing to hand-write TOML syntax.

**Alternative considered:** Raw TOML string (`xdg.configFile."herdr/config.toml".text = ''...''`). Rejected because there's no structural validation — a misplaced bracket or missing quote silently produces invalid TOML.

### `xdg.configFile` (not `home.file`)

`xdg.configFile` places files under `~/.config/`, which is where herdr expects its config. `home.file` would require the full path `".config/herdr/config.toml"` — functionally equivalent but `xdg.configFile` is the idiomatic choice for XDG config directories. The `openspec.nix` file already uses this pattern.

### Dedicated `home-manager/herdr.nix` (not inline in `home.nix`)

Follows the existing convention: each tool gets its own file (`tmux.nix`, `ai.nix`, `terminal.nix`). This keeps `home.nix` as a clean import list and makes each tool's config self-contained.

## Risks / Trade-offs

- **Read-only config**: `xdg.configFile` creates a symlink to the Nix store, so `herdr config reset-keys` can't write to it. Users who want to add custom keybindings must do so through `herdr.nix`. Mitigation: this is documented in the proposal, and `herdr server reload-config` still works for live iteration before committing to Nix.
- **TOML key ordering**: `pkgs.formats.toml` sorts keys alphabetically within each section. If herdr ever depends on key ordering (unlikely for TOML), this could cause issues. No known cases.
