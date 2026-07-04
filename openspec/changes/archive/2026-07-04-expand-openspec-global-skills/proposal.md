## Why

The OpenSpec global skills deployed via home-manager (skills, prompts, commands for Pi and OpenCode) only cover 5 of the 11 workflow artifacts. The missing 6 workflows (bulk-archive, continue, ff, new, onboard, verify) exist as project-local skills in `.pi/skills/` but are not available globally — meaning they're inaccessible when using Pi or OpenCode in projects that don't have their own OpenSpec setup. This limits the agent's ability to use the full experimental workflow.

## What Changes

- Add the 6 missing OpenSpec skill directories to `pkgs/openspec-agent-files/` for both Pi (`.pi/skills/`) and OpenCode (`.opencode/skills/`)
- Add the 6 missing prompt files to `pkgs/openspec-agent-files/.pi/prompts/`
- Add the 6 missing command files to `pkgs/openspec-agent-files/.opencode/commands/`
- Update `home-manager/openspec.nix` to link all 11 skill directories (up from 5) and all 11 prompt/command files (up from 5) into global agent config directories
- Update `openspec/specs/openspec-global-skills/spec.md` to reflect the expanded set and correct the incomplete skill count

## Capabilities

### New Capabilities
<!-- None — this extends an existing capability, not introducing a new one -->

### Modified Capabilities
- `openspec-global-skills`: Expand the global skill deployment from 5 workflows to all 11 (add bulk-archive, continue, ff, new, onboard, verify). Update spec scenarios to reflect the full workflow set.

## Impact

- `pkgs/openspec-agent-files/` — add 6 new skill dirs (18 files: 6 Pi skills + 6 Pi prompts + 6 OpenCode commands)
- `home-manager/openspec.nix` — add 18 new `home.file` / `xdg.configFile` entries
- `openspec/specs/openspec-global-skills/spec.md` — update requirement descriptions and scenarios
- No breaking changes; existing 5-workflow links remain intact
