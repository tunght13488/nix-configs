## Why

The repo has no first-class Python tooling: `python313` only appears as an implementation detail of `tmux`'s powerline, and there is no `uv` available on PATH. `uv` is the modern default for Python project management (interpreter installs, venvs, package installs, lockfiles). Adding it unblocks any new Python project work without disturbing the existing nixpkgs-owned `python313` used by tmux.

## What Changes

- Add `unstable.uv` to `home.packages` in `home-manager/home.nix`, slotting it next to the existing `unstable.openspec` and `unstable.zed-editor` entries (same idiom).
- No new file, no overlay, no session variables, no `.uv.toml`, no devShell. uv manages its own interpreter downloads and venvs at runtime, outside Nix's purview — intentional for uv's model.
- `tmux.nix`'s `pkgs.python313` / `pkgs.python313Packages.powerline` stays untouched. The two concerns (nixpkgs-python-as-powerline-host vs. uv-managed Python for projects) coexist independently.

## Capabilities

### New Capabilities
- `python-toolchain`: make the `uv` Python project manager available on the user's PATH so new Python projects can be created/managed without hand-rolling venvs or pulling interpreter packages through nixpkgs.

### Modified Capabilities
<!-- None. No existing spec-level behavior changes. -->

## Impact

- **Affected code**: `home-manager/home.nix` only (one line addition to the existing `home.packages` list).
- **Closure**: pulls `unstable.uv` (Rust binary, ~tens of MB) into the home-manager closure.
- **Runtime state**: uv will download and cache Python interpreters under `~/.local/share/uv/` at runtime; this is outside Nix's purview and not managed declaratively. Intended.
- **Coexistence**: `tmux.nix:61` (`pkgs.python313`) and `nix-ld.nix:87` (`python3`) are unrelated to this change and remain as-is.
- **No breaking changes.**