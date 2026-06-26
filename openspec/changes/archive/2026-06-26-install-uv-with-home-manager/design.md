## Context

The repo's home-manager layer has no dedicated Python module. `python313` appears in `tmux.nix:61` solely to host the `powerline` tmux statusline; it is an implementation detail, not a user-facing toolchain. There is no `uv` (or any Python project manager) on PATH. Flake inputs pin `nixos-25.11`, and a `pkgs.unstable` overlay is already in use for fast-moving tools (`unstable.openspec`, `unstable.zed-editor` in `home.nix:79,85`). `nix-ld` is enabled (`nixos/nix-ld.nix`), so uv's downloaded standalone-Python binaries will run without FHS friction.

## Goals / Non-Goals

**Goals:**
- Make `uv` available on `tung`'s PATH so any new Python project can be initialized (`uv init`), pinned (`uv python pin`), and have its interpreter installed (`uv python install`) without touching nixpkgs.
- Match the existing `unstable.<tool>` idiom already used for `openspec` and `zed-editor`.

**Non-Goals:**
- Not adding a `python.nix` module (user explicitly chose Fork 1 option C: inline in `home.nix`).
- Not migrating `tmux.nix`'s `pkgs.python313` to uv — that interpreter exists only to host the powerline derivation and stays nixpkgs-owned.
- Not creating any Python devShell in `flake.nix` for now.
- Not configuring `UV_*` env vars, `~/.config/uv/uv.toml`, cache directory, or `UV_PYTHON_INSTALL_DIR`. uv's defaults apply.
- Not pinning a specific uv version beyond "whatever unstable provides at build time."

## Decisions

### Decision 1 — Install via `home.packages`, not a new module
Add `unstable.uv` to the existing `home.packages = with pkgs; [ ... ]` block in `home-manager/home.nix` (the same list already containing `unstable.openspec` and `unstable.zed-editor`).

**Alternatives considered:**
- New `home-manager/python.nix` module (modeled on `go.nix` or `node.nix`): rejected — user chose inline placement; a module with only `home.packages = [ unstable.uv ]` adds a file + import line for zero expressive benefit.
- NixOS-level (`environment.systemPackages`) in `nixos/configuration.nix`: rejected — uv is for the user's project work; `tung` is the sole user, so home-manager placement is sufficient and consistent with `openspec`/`zed-editor`.

### Decision 2 — Use `unstable.uv`, not `pkgs.uv`
uv ships weekly-ish; nixpkgs 25.11's `uv` will lag. The `pkgs.unstable` overlay is already wired (`overlays/default.nix`) and actively used.

**Alternatives considered:**
- `pkgs.uv` (stable 25.11): would lag behind Astral's releases; user would hit fixed-known-bugs while the stable branch catches up.
- Custom `pkgs.uv` derivation in `pkgs/`: unnecessary — unstable tracks uv well; no vendoring justification.

### Decision 3 — Let uv own runtime Python state, outside Nix
uv will download `python-build-standalone` interpreters into `~/.local/share/uv/python/` and cache wheels under `~/.cache/uv/` at runtime. This is intentionally outside Nix's purview.

**Rationale:** uv's whole value proposition is "one tool manages interpreters + venvs + packages." Re-implementing that declaratively via nixpkgs `python3XX` packages would fight uv's model and reintroduce the multi-version verbosity this change is meant to escape. `nix-ld` ensures uv-downloaded Pythons execute fine on NixOS.

**Alternatives considered:**
- Declaring `UV_PYTHON_INSTALL_DIR = "$XDG_DATA_HOME/uv/python"` or similar: rejected for now — would be a future hardening, not part of this minimal change.
- Pulling project interpreters from nixpkgs and using uv only for venvs/packages: rejected — defeats the point; also conflicts with Fork 2 decision (coexist, not merge).

## Risks / Trade-offs

- **[Risk] Closure size creep**: `unstable.uv` is a Rust binary, ~tens of MB plus runtime dependencies. → **Mitigation**: one-time cost; acceptable for a tool expected to see regular use. `make home-build` will surface the delta.
- **[Risk] Runtime state diverges across machines/users**: uv-downloaded interpreters live in `~/.local/share/uv/`, unmanaged. On a fresh machine these re-download. → **Mitigation**: accepted trade-off for the uv-model benefit; the Nix config is already single-machine (`nixos-vmware`).
- **[Risk] Bullets drift between unstable and uv upstream behavior**: an unstable-channel bump could land a uv release with behavior changes. → **Mitigation**: `make update` runs `nix flake update`; user reviews the diff before applying. Same risk profile as existing `unstable.*` consumers.
- **[Trade-off] Drift between tmux's `python313` and uv-managed Pythons**: two Python ecosystems side by side. → **Accepted**: they serve different purposes and never interact; powerline runs from the nix-store path, project work runs from uv-managed interpreters. No cross-contamination path.

## Migration Plan

1. Add the line to `home-manager/home.nix`.
2. Run `make home-build` to verify the home-manager configuration evaluates and builds.
3. (User step, not automated) Run `make home` to activate; then `uv --version` and `uv python install 3.12` to smoke-test.
4. **Rollback**: revert the one-line addition; `make home` again. uv-downloaded state under `~/.local/share/uv/` is left behind (out of Nix's control) but harmless.

## Open Questions

None. All four forks resolved during explore. The change is fully specified.