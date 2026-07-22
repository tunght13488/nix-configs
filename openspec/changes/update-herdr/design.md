## Context

Herdr is installed as a home-manager package from a pinned flake input (`github:ogulcancelik/herdr/v0.7.4`). The package is built from the upstream flake's own `nix/package.nix` without overriding nixpkgs. A config baseline is generated via `pkgs.formats.toml` and bootstrapped on first activation. Agent skill files are copied from the flake source via a dedicated derivation (`pkgs/herdr-agent-files.nix`).

Upstream released v0.7.5 on 2026-07-21 with no changes to the Nix package structure, the SKILL.md path, or the config schema that would break our baseline.

## Goals / Non-Goals

**Goals:**
- Update the herdr flake input from v0.7.4 to v0.7.5
- Verify the build succeeds with `make home-build`
- Verify the existing config baseline remains valid per v0.7.5's stricter `herdr config check`

**Non-Goals:**
- Adopt new config options (`ui.sidebar_start_collapsed`, `ui.prompt_new_workspace_name`) in the baseline
- Update the herdr-agent-skill spec (SKILL.md path and structure unchanged)
- Add plugin or agent-CLI workflow changes
- Change the prefix or theme

## Decisions

1. **URL-only bump**: Change `inputs.herdr.url` from `v0.7.4` to `v0.7.5` in `flake.nix`, then run `nix flake lock --update-input herdr`. No other code changes needed.

   - **Why**: The Nix package definition (`nix/package.nix`), overlay structure, and SKILL.md path are unchanged between versions. Our config baseline uses only keys that exist in both versions.

2. **No config baseline changes**: The new optional keys (`ui.sidebar_start_collapsed`, `ui.prompt_new_workspace_name`) are not added to the baseline now. They can be adopted later in a separate change.

   - **Why**: v0.7.5 adds `herdr config check` which will flag unknown keys. Our existing baseline contains only well-known keys (`onboarding`, `keys.prefix`, `theme`, `ui.agent_panel_sort`, `ui.show_agent_labels_on_pane_borders`, `ui.toast.delivery`), all of which are valid in v0.7.5.

3. **Keep all existing imports and overlays unchanged**: `overlays/default.nix`, `home-manager/herdr.nix`, and `pkgs/herdr-agent-files.nix` require no modifications.

   - **Why**: The flake output structure (`overlays.default`, `packages.${system}.default`) is identical. The `herdrSrc` passed to `herdr-agent-files.nix` still contains `SKILL.md` at the same relative path.

## Risks / Trade-offs

- **Breaking plugin change**: v0.7.5 makes plugins global per user instead of per session. This is a runtime behavior change, not a packaging concern — no action needed in our Nix config.
- **Lock file churn**: `nix flake lock --update-input herdr` may pull in transitive dependency updates from the herdr flake's own lock. If the build fails, evaluate whether the upstream flake needs a follow on a nixpkgs input (currently explicitly avoided per the existing spec).
