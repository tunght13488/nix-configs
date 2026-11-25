# Design

## Context

See `proposal.md` - Why. `home-manager/pi-sandbox.nix` defines the shared `pi-box` base profile and deploys it as `~/.config/nono/profiles/pi-box.json`. Its `filesystem.allow` list contains paths shared by every pi-box session; per-project profiles and generated overlays serve different, narrower purposes.

## Goals / Non-Goals

**Goals:**
- Provide read-write access to `~/.config/herdr-app/mods` in every default pi-box session.
- Keep the grant limited to the mods directory.

**Non-Goals:**
- Grant access to the rest of `~/.config/herdr-app`.
- Change project templates, per-run overlays, wrapper behavior, or Herdr itself.

## Decisions

- Add `${homeDir}/.config/herdr-app/mods` to the shared base profile's `filesystem.allow` list. This matches the requested persistent, read-write access and uses the existing mechanism for host paths shared by all pi-box sessions.
- Do not add a project-specific template grant: it would require each project to opt in and would not affect the default shared policy. Do not grant the parent `~/.config/herdr-app`, which would expose unrelated configuration.

## Risks / Trade-offs

- **Every pi-box session can modify the host's Herdr mods** → Keep the grant scoped to `mods`; retain the existing access boundaries for other Herdr configuration.

## Migration Plan

No data migration or wrapper change is needed. Rebuild and deploy the Home Manager profile, then validate the profile and confirm a sandboxed read and write under `~/.config/herdr-app/mods` are reflected at the same host path. To roll back, remove the grant and redeploy; files already changed under `mods` remain on the host.
