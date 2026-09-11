## Context

See proposal.md - Why. Herdr is consumed as a pinned flake input (`github:herdrdev/herdr/v0.8.2`) whose overlay provides `pkgs.herdr`; the agent skill is sourced from the same input via `pkgs/herdr-agent-files.nix`. The upstream file layout relevant to packaging (`skills/herdr/SKILL.md`, `nix/package.nix`) and the flake outputs (`overlays.default`, `packages.<system>.herdr`) are confirmed unchanged at tag `v0.9.0`, and the v0.9.0 release explicitly fixes Nix crate fetching via a static CDN (#3505), so this is a tag-only bump.

## Goals / Non-Goals

**Goals:**
- Pin `inputs.herdr` to tag `v0.9.0` and regenerate the lock entry
- Confirm the home-manager config baseline (`home-manager/herdr.nix`) validates against v0.9.0 (`herdr config check`), with attention to the `one-dark` built-in theme name and `ui.toast.delivery = "system"`
- Confirm the agent-skill derivation still builds and links from the bumped input

**Non-Goals:**
- Adopting new v0.9.0 config keys (`ui.pane_borders` string values, `terminal.kitty_graphics`, sidebar text/metadata color rules, per-mode custom theme overrides) into the Nix baseline — they are optional and can be trialed via the writable `~/.config/herdr/config.toml`
- Any change to `pkgs/herdr-agent-files.nix` or the skill symlink wiring in `home-manager/herdr.nix`
- Preview/nightly herdr builds
- Mitigating upstream breaking changes that do not touch this setup: removal of `--no-session` (unused here) and live-start lifecycle subscriptions (API-client concern)

## Decisions

- **Bump to the latest stable tag `v0.9.0`** — it is the newest stable release; there are no stable tags between v0.8.2 and v0.9.0. Alternative considered: staying on v0.8.2, rejected because v0.9.0 fixes the Nix crate-download endpoint (directly affects this install method), memory/CPU behavior in busy sessions, and Pi/OMP agent-state detection used daily here.
- **Tag-only flake input change** (`flake.nix` URL + `nix flake lock --update-input herdr`), matching the established pattern from the archived `update-herdr-0-8-0` and `update-herdr-0-8-2` changes. No `follows` override is introduced; herdr builds with its own nixpkgs. Alternative considered: overriding `nixpkgs` via `follows` to deduplicate the closure, rejected to stay consistent with the existing spec requirement.
- **Verify rather than adopt for new config surface** — v0.9.0 adds only optional keys and keeps existing boolean `ui.pane_borders` values working, so the baseline stays as-is. Baseline keys (`onboarding`, `keys.prefix`, `theme.name`/`theme.auto_switch`, `ui.agent_panel_sort`, `ui.show_agent_labels_on_pane_borders`, `ui.toast.delivery`) were confirmed present in the v0.9.0 config model source; verification still runs `herdr config check` as the authority. If validation reports an unknown or retired key, fix the baseline minimally within this change.
- **Kitty graphics now default-on** is a visible behavior change in compatible terminals, but it is config-neutral: it requires no baseline entry (disable path is `terminal.kitty_graphics = false` if unwanted), and this host's terminals opt in/out themselves. No action taken.
- **Skill content flows through automatically** — the updated upstream SKILL.md is picked up through the bumped flake input with no derivation changes, since `pkgs/herdr-agent-files.nix` references the input path rather than a pinned copy.

## Risks / Trade-offs

- [v0.9.0 changes config validation and the baseline fails `herdr config check` (e.g., unknown theme name or retired key)] → Run `herdr config check` against the v0.9.0 binary before switching; adjust the offending key in `home-manager/herdr.nix` as a minimal compatibility fix within this change
- [The bumped input's own nixpkgs/rust-overlay advance, enlarging the closure or breaking the build] → Build with `make home-build` before switching; if the herdr package fails to build, hold at v0.8.2 and report upstream
- [Client-rendered UI (#3487) or the removed `--no-session` mode changes day-to-day workflows] → Out of scope for packaging; the server model is unchanged for local single-user use. If a regression appears in daily use, downgrade by reverting the tag and re-locking
- [Writable `~/.config/herdr/config.toml` on disk may contain stale keys from past experiments] → Out of scope for the Nix baseline; stale keys surface via `herdr config check` on the live file after switch
