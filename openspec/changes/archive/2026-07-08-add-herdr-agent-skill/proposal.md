## Why

The herdr agent skill is currently installed via `npx skills add` — an out-of-band npm-based method that isn't reproducible, isn't tracked in the Nix flake lock, and doesn't survive system rebuilds. The skill file exists in the herdr flake source (`SKILL.md` at repo root) but isn't wired into the Nix config. Adding it as a Nix derivation, managed by home-manager, ensures the herdr skill is versioned alongside the herdr binary and available to agents after every `home-manager switch`.

## What Changes

- Add a Nix derivation (`pkgs/herdr-agent-files.nix`) that extracts `SKILL.md` from the herdr flake source
- Expose the derivation via the `additions` overlay as `herdrAgentFiles`
- Extend `home-manager/herdr.nix` to link the skill file into Pi (`~/.pi/agent/skills/herdr/`) and OpenCode (`~/.config/opencode/skills/herdr/`) agent directories, mirroring the pattern established by `openspec.nix`
- No other files changed; the existing herdr config bootstrapping in `herdr.nix` is unaffected

## Capabilities

### New Capabilities
- `herdr-agent-skill`: Agent skill files for herdr terminal multiplexer, installed globally for Pi and OpenCode via home-manager

### Modified Capabilities
<!-- None -->

## Impact

- **New file**: `pkgs/herdr-agent-files.nix` — derivation copying `SKILL.md` from `inputs.herdr.outPath`
- **Modified file**: `overlays/default.nix` — registration in `additions` overlay
- **Modified file**: `home-manager/herdr.nix` — new `home.file` and `xdg.configFile` entries for skill linking
- **Dependencies**: Depends on existing `inputs.herdr` flake input (already pinned to v0.7.3 which includes `SKILL.md`)
