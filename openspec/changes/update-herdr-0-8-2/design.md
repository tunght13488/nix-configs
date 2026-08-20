## Context

See proposal.md - Why. Herdr is consumed as a pinned flake input (`github:herdrdev/herdr/v0.8.0`) whose overlay provides `pkgs.herdr`; the agent skill is sourced from the same input via `pkgs/herdr-agent-files.nix`. The upstream file layout relevant to packaging (`skills/herdr/SKILL.md`, `nix/package.nix`) is confirmed unchanged at tag `v0.8.2`, so this is a tag-only bump.

## Goals / Non-Goals

**Goals:**
- Pin `inputs.herdr` to tag `v0.8.2` and regenerate the lock entry
- Confirm the home-manager config baseline (`home-manager/herdr.nix`) validates against v0.8.2 (`herdr config check`), with attention to the `one-dark` built-in theme name now being strictly checked
- Confirm the agent-skill derivation still builds and links from the bumped input

**Non-Goals:**
- Adopting new v0.8.2 config keys (`ui.window_title`, tab-bar status entries, `keys.move_tab_*`, `keys.resize_pane_*`, `ui.pane_outer_borders`, `theme.custom.*`) into the Nix baseline — they are optional and can be trialed via the writable `~/.config/herdr/config.toml`
- Any change to `pkgs/herdr-agent-files.nix` or the skill symlink wiring in `home-manager/herdr.nix`
- Preview/nightly herdr builds

## Decisions

- **Bump to the latest stable tag `v0.8.2`, skipping nothing** — there is no `v0.8.1` tag upstream; the project went straight from v0.8.0 to v0.8.2. Alternative considered: staying on v0.8.0, rejected because v0.8.2 fixes CPU/latency regressions and agent state detection bugs that affect daily use.
- **Tag-only flake input change** (`flake.nix` URL + `nix flake lock --update-input herdr`), matching the established pattern from the archived `update-herdr-0-8-0` change. No `follows` override is introduced; herdr builds with its own nixpkgs. Alternative considered: overriding `nixpkgs` via `follows` to deduplicate the closure, rejected to stay consistent with the existing spec requirement.
- **Verify rather than adopt for new config surface** — v0.8.2 adds only optional keys, so the baseline stays as-is. The one behavioral risk to baseline validity is `herdr config check` now rejecting unknown built-in theme names (#2452); verification covers it. If validation reveals `one-dark` is not a built-in theme, fix the baseline theme name as part of this change.
- **Skill content flows through automatically** — the updated upstream SKILL.md (now matching stable CLI/lifecycle behavior, #2847) is picked up through the bumped flake input with no derivation changes, since `pkgs/herdr-agent-files.nix` references the input path rather than a pinned copy.

## Risks / Trade-offs

- [v0.8.2 changes config validation and the baseline fails `herdr config check` (e.g., unknown theme name or retired key)] → Run `herdr config check` against the v0.8.2 binary before switching; adjust the offending key in `home-manager/herdr.nix` as a minimal compatibility fix within this change
- [The bumped input's own nixpkgs advances, enlarging the closure or breaking the build] → Build with `make home-build` before switching; if the herdr package fails to build, hold at v0.8.0 and report upstream
- [Writable `~/.config/herdr/config.toml` on disk may contain retired keys from past experiments] → Out of scope for the Nix baseline, but note that v0.8.2 explicitly tolerates the retired `ui.agent_panel_scope` key (#2292); other stale keys surface via `herdr config check`
