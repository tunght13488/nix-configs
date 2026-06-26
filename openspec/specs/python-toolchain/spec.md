## Purpose

Provide the `uv` Python project manager on the user's PATH via the existing `unstable` overlay, without disturbing the nixpkgs-owned `python313` used by tmux's powerline, and without adding Python devShells, `UV_*` env vars, or uv configuration files.

## Requirements

### Requirement: uv available on user PATH
The home-manager configuration SHALL install `unstable.uv` such that the `uv` binary is on `tung`'s PATH after `make home` is applied.

#### Scenario: uv is callable from a new shell
- **WHEN** the user opens a new zsh session after `make home` has been applied
- **THEN** `uv --version` succeeds and prints a version string

#### Scenario: uv binary resolves to the unstable-derivation path
- **WHEN** the user runs `which uv` after `make home` has been applied
- **THEN** the resolved path points under the nix store path produced from the `unstable` flake input (not a manually installed binary)

### Requirement: Placement follows existing unstable-tool idiom
The `uv` package SHALL be added to the existing `home.packages = with pkgs; [ ... ]` block in `home-manager/home.nix`, alongside the existing `unstable.openspec` and `unstable.zed-editor` entries — not via a new module file, not via a NixOS-level package, not via an overlay.

#### Scenario: No new file is introduced
- **WHEN** the change is inspected via `git status`
- **THEN** the only modified file under `home-manager/` is `home.nix`; no `python.nix` (or similar) is created

#### Scenario: Single-line addition to the existing package list
- **WHEN** the diff of `home-manager/home.nix` is reviewed
- **THEN** exactly one new line referencing `unstable.uv` appears inside the existing `home.packages` list, consistent in style with the adjacent `unstable.openspec` / `unstable.zed-editor` lines

### Requirement: tmux's nixpkgs python313 is untouched
The change SHALL NOT modify `home-manager/tmux.nix`, `home-manager/tmux.nix`'s reference to `pkgs.python313`, or `pkgs.python313Packages.powerline`. The nixpkgs-owned Python used to host powerline and the uv-managed Python ecosystem for projects SHALL coexist independently.

#### Scenario: tmux powerline still sources from nixpkgs python313
- **WHEN** tmux starts after `make home` has been applied
- **THEN** the tmux statusline renders via powerline sourced from `pkgs.python313Packages.powerline` (unchanged behavior)

#### Scenario: tmux.nix is unchanged
- **WHEN** `git diff home-manager/tmux.nix` is run on the change
- **THEN** the output is empty (no diff)

### Requirement: No Python devShell or uv configuration is added
The change SHALL NOT add a Python `devShells.*` entry to `flake.nix`, SHALL NOT set `UV_*` environment variables, SHALL NOT create `~/.config/uv/uv.toml` via `home.file`, and SHALL NOT add a `UV_PYTHON_INSTALL_DIR` / `UV_CACHE_DIR` session variable. uv's defaults apply.

#### Scenario: No new devShell appears
- **WHEN** `nix flake show --no-write-lock-file` is run after the change
- **THEN** the set of `devShells.*` entries is unchanged (no `python` / `uv` shell is introduced)

#### Scenario: No session variables are set
- **WHEN** `git diff home-manager/home.nix` is inspected
- **THEN** the `home.sessionVariables` block is unchanged (no `UV_*` keys added)

#### Scenario: No uv config file is declared
- **WHEN** `git diff` across the change is inspected
- **THEN** no `home.file` entry creates `".config/uv/uv.toml"` or similar