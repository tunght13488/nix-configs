## Context

Herdr is installed as a home-manager package from a pinned flake input. Today the input points at `github:ogulcancelik/herdr/v0.7.5`. The package builds from the upstream flake's own `nix/package.nix` without overriding nixpkgs. A config baseline is generated via `pkgs.formats.toml` and bootstrapped on first activation. Agent skill files are copied from the flake source by `pkgs/herdr-agent-files.nix`, which symlinks `${herdrSrc}/SKILL.md` from the repository root.

Upstream v0.8.0 (released 2026-08-03) introduces three deltas relevant to our config:

1. The GitHub repository migrated from `ogulcancelik/herdr` to `herdrdev/herdr`. Tags still resolve via GitHub's redirect, but upstream's canonical installation links now use `herdrdev/herdr`.
2. The bundled `SKILL.md` moved out of the repo root to `skills/herdr/SKILL.md`. The v0.8.0 Nix package (`nix/package.nix`) bundles it from that path and `Cargo.toml` lists `skills/herdr/SKILL.md` as an asset, supporting the new `herdr --skill` command.
3. New optional config keys were added: `ui.pane_scrollbars` and `ui.tab_bar_position`. The release also relicensed Herdr from AGPL-3.0-or-later to Apache-2.0 — a metadata change with no packaging impact here.

Herdr was also relicensed to Apache-2.0; this does not change how we consume it.

## Goals / Non-Goals

**Goals:**
- Update the herdr flake input to `github:herdrdev/herdr/v0.8.0` and refresh `flake.lock`
- Fix `pkgs/herdr-agent-files.nix` so the agent-skill derivation resolves `SKILL.md` at its new path `skills/herdr/SKILL.md`
- Verify the build succeeds with `make home-build` and that `herdr --skill` works against the v0.8.0 binary
- Verify the existing config baseline remains valid per v0.8.0's config validation

**Non-Goals:**
- Adopting the new optional config keys (`ui.pane_scrollbars`, `ui.tab_bar_position`) into the baseline — deferred to a separate change
- Switching the home-manager skill linking strategy to depend on `herdr --skill` output instead of the flake source (the flake-source symlink approach still works and is simpler)
- Changing the prefix, theme, or any existing config baseline keys
- Updating the `herdr-agent-skill` skill content itself (the upstream SKILL.md is consumed verbatim)

## Decisions

1. **URL organization + tag bump**: Change `inputs.herdr.url` from `github:ogulcancelik/herdr/v0.7.5` to `github:herdrdev/herdr/v0.8.0`, then run `nix flake lock --update-input herdr`.

   - **Why**: Upstream migrated to the `herdrdev` organization and v0.8.0 is the new stable tag. Using the canonical org avoids relying on GitHub's repo-transfer redirect and keeps our config aligned with upstream's documented install paths.
   - **Alternatives**: Keep `ogulcancelik/herdr/v0.8.0` — the redirect would likely still resolve, but it is no longer the canonical home and could break if the old org is reclaimed or the redirect is removed.

2. **Agent-skill source path fix**: In `pkgs/herdr-agent-files.nix`, change the symlinked source from `${herdrSrc}/SKILL.md` to `${herdrSrc}/skills/herdr/SKILL.md`.

   - **Why**: v0.8.0 moved `SKILL.md` out of the repo root. Without this change the `runCommand` derivation fails during the `ln -s` because the source path no longer exists. This is the minimal fix that preserves the existing "link from flake source" strategy and the `.pi/` + `.opencode/` output layout.
   - **Alternatives**: Generate the skill files by running `herdr --skill` at build time. Rejected — it adds a herdr runtime build dependency to a trivial file-copy derivation and couples the derivation to the binary's output format. The flake-source symlink is simpler and already established.

3. **No config baseline changes**: Do not add `ui.pane_scrollbars` or `ui.tab_bar_position` to the baseline now.

   - **Why**: Both are optional. The current baseline keys (`onboarding`, `keys.prefix`, `theme`, `ui.agent_panel_sort`, `ui.show_agent_labels_on_pane_borders`, `ui.toast.delivery`) all remain valid in v0.8.0, so no keys must be removed either. Adopting the new keys is a separate, opt-in decision.

4. **Keep overlays, home-manager module, and import list unchanged**: `overlays/default.nix`, `home-manager/herdr.nix`, and `home-manager/home.nix` require no modifications.

   - **Why**: The flake output structure (`overlays.default`, `packages.${system}.default`) is identical in v0.8.0. The `herdrSrc` passed to `herdr-agent-files.nix` is still `inputs.herdr.outPath`; only the relative path to `SKILL.md` within it changes, which is handled inside the derivation itself.

## Risks / Trade-offs

- **Lock file churn** → `nix flake lock --update-input herdr` may pull transitive dependency updates from the herdr flake's own lock (its nixpkgs is pinned to `nixos-unstable`). If the build fails, evaluate whether a transitive input changed; herdr's nixpkgs is intentionally not overridden via `follows`, per spec.
- **SKILL.md path drift on future upstream moves** → The derivation now hardcodes `skills/herdr/SKILL.md`. If upstream relocates the skill again, the build breaks loudly at the `ln -s` step, which is acceptable (fail-fast) and surfaces during `make home-build`.
- **Old `ogulcancelik/herdr` org** → If any external reference (e.g. a cached `flake.lock` on another machine) still points at the old org, GitHub's redirect covers it for now. Confirming the canonical `herdrdev/herdr` URL in `flake.nix` removes this ambiguity going forward.

## Migration Plan

1. Update `inputs.herdr.url` in `flake.nix`.
2. Run `nix flake lock --update-input herdr`.
3. Update the `SKILL.md` source path in `pkgs/herdr-agent-files.nix`.
4. Run `nix flake check --no-write-lock-file` and `make home-build` to verify evaluation and the agent-skill derivation.
5. Rollback: revert `flake.nix`, `pkgs/herdr-agent-files.nix`, and `flake.lock`. The previous archived change `2026-08-04-update-herdr` documents the v0.7.5 baseline.

## Open Questions

None. The skill relocation and org migration are confirmed against the v0.8.0 tag tree (no root `SKILL.md`; skill lives at `skills/herdr/SKILL.md`; `nix/package.nix` bundles it from there).