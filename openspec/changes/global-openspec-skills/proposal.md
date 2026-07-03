## Why

OpenSpec is already used in the nix-configs project via project-local Pi skills (`.pi/skills/openspec-*`), but it is unavailable in other projects and not configured for OpenCode. Managing these files via home-manager ensures both Pi and OpenCode can use the spec-driven workflow in any project, with files kept in sync with the installed OpenSpec CLI version.

## What Changes

- Add a Nix derivation (`pkgs/openspec-agent-files.nix`) that runs `openspec init --tools pi,opencode` at build time to generate current-version skill, prompt, and command files
- Add a home-manager module (`home-manager/openspec.nix`) that links the generated files to global agent config directories via individual `home.file` and `xdg.configFile` entries
- Import the new module in `home-manager/home.nix`

## Capabilities

### New Capabilities

- `openspec-global-skills`: OpenSpec workflow skills available globally to Pi and OpenCode in any project directory, generated and managed via Nix home-manager

### Modified Capabilities

<!-- None - this is a new capability with no requirement changes to existing specs -->

## Impact

- New file: `pkgs/openspec-agent-files.nix` — derivation wrapping `openspec init`
- New file: `home-manager/openspec.nix` — home-manager module with `home.file` and `xdg.configFile` entries
- Modified: `home-manager/home.nix` — imports the new openspec module
- Target directories populated at build time:
  - `~/.pi/agent/skills/openspec-{apply-change,archive-change,explore,propose}/SKILL.md`
  - `~/.pi/agent/prompts/opsx-{apply,archive,explore,propose}.md`
  - `~/.config/opencode/skills/openspec-{apply-change,archive-change,explore,propose}/SKILL.md`
  - `~/.config/opencode/commands/opsx-{apply,archive,explore,propose}.md`
- No changes to existing project-local OpenSpec files
