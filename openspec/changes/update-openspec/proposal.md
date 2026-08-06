## Why

The OpenSpec CLI and its agent integration files (Pi prompts/skills, OpenCode commands/skills) are pinned to upstream v1.5.0 across two places in this flake: the `unstable.openspec` override in `overlays/default.nix` and the agent-files derivation in `pkgs/openspec-agent-files.nix`. Upstream has advanced to v1.8.0, adding a new `/opsx-update` workflow (v1.6.0), generated skill permissions that pre-approve the OpenSpec CLI (v1.6.0), `openspec update` self-updater (v1.7.0), per-operation guidance in `openspec instructions apply|archive` (v1.7.0), and `agents`/`.agents/skills` target plus `retire_capabilities` archive handling (v1.8.0). Staying on v1.5.0 means the installed CLI and the generated agent files lag three minor releases behind, miss the new `update` workflow, and re-prompt for tool approval on every OpenSpec command.

## What Changes

- Bump the pinned OpenSpec version from v1.5.0 to v1.8.0 in both `pkgs/openspec-agent-files.nix` (`version`, `rev`, `hash`) and `overlays/default.nix` (`unstable.openspec` overrideAttrs: `version`, `tag`, `hash`, and `pnpmDeps` hash).
- Regenerate the agent integration files from v1.8.0 source, which adds a 12th workflow `update` (`opsx-update.md` prompt, `openspec-update-change` skill, `opsx-update.md` command) and updates frontmatter so generated skills pre-approve the OpenSpec CLI (`allowed-tools: Bash(openspec:*)` is already present; v1.6.0+ tightens permission pre-approval across generated skills/commands).
- Add the new `update` workflow file links to `home-manager/openspec.nix` (Pi prompt, Pi skill, OpenCode command, OpenCode skill) so the 12th workflow is available globally.
- Keep the existing Pi + OpenCode tool targets; the new v1.6–1.8 targets (Oh My Pi `.omp`, TRAE, `.agents/skills`, MiniMax, Rovo, Copilot cloud) are out of scope for this config and are not wired in.
- Verify with `make home-build`; do not run `make home`.

## Capabilities

### New Capabilities
<!-- None. Both affected capabilities already have specs. -->

### Modified Capabilities
- `openspec-agent-generation`: The derivation now fetches and builds v1.8.0 source and emits 12 pi prompts, 12 pi skills, 12 opencode commands, and 12 opencode skills (the new `update` workflow). Generated files carry v1.6+ skill-permission frontmatter. The "exactly 11" counts in the spec become 12.
- `openspec-global-skills`: Home-manager links the new `update` workflow files globally for both Pi and OpenCode, so the global skill/prompt/command set grows from 11 to 12 workflows.

## Impact

- `pkgs/openspec-agent-files.nix` — `version`, `rev`, `hash` bump to v1.8.0.
- `overlays/default.nix` — `unstable.openspec` overrideAttrs: `version`, `tag`, `hash`, `pnpmDeps` hash bump to v1.8.0.
- `home-manager/openspec.nix` — add four `update` workflow `home.file`/`xdg.configFile` link entries (Pi prompt + skill, OpenCode command + skill).
- `pkgs/generate-agent-files.mjs` — unchanged in structure (still bundles pi + opencode adapters via esbuild); verify it still resolves against v1.8.0 source.
- Build verification via `make home-build`; the home-manager activation that applies the new links is run by the user.
- No breaking changes to consumers beyond the added `update` workflow and updated generated file contents.