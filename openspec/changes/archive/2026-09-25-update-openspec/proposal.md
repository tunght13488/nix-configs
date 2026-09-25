## Why

The OpenSpec CLI and its generated agent integration files (Pi prompts/skills, OpenCode commands/skills) are pinned to upstream v1.8.0 in two places in this flake: the `unstable.openspec` override in `overlays/default.nix` and the agent-files derivation in `pkgs/openspec-agent-files.nix`. Upstream has advanced to v1.13.2, adding `openspec show --diff` and `openspec status --all` (v1.11.0), findings-only validation reports (v1.12.0), `validate --archived` (v1.9.0), apply warnings for changes with no delta specs (v1.13.0), code-grounded planning in propose/ff workflows (v1.12.0), and a large batch of archive/delta-parser correctness fixes and CLI security hardening (v1.13.x). Staying on v1.8.0 leaves the installed CLI and the generated agent files five releases behind.

## What Changes

- Bump the pinned OpenSpec version from v1.8.0 to v1.13.2 in both `pkgs/openspec-agent-files.nix` (`version`, `rev`, `hash`) and `overlays/default.nix` (`unstable.openspec` overrideAttrs: `version`, `tag`, `hash`, and `pnpmDeps` hash).
- Regenerate the agent integration files from v1.13.2 source. The core profile still emits the same 12 workflows (verified against upstream `getSkillTemplates`), so file counts and `home-manager/openspec.nix` link entries are unchanged; only generated file contents change (updated workflow guidance, e.g. explore/propose improvements and task rules).
- `pkgs/generate-agent-files.mjs` stays unchanged: all modules it imports (`skill-generation.ts`, `pi.ts`, `opencode.ts`, `generator.ts`, `command-references.ts`, `invocation.ts`) still exist at v1.13.2 with compatible exports (verified against the upstream tree).
- Verify with `make home-build`; do not run `make home`.

## Capabilities

### New Capabilities
<!-- None. The affected capability already has a spec. -->

### Modified Capabilities
- `openspec-agent-generation`: Version-specific scenarios are re-baselined to v1.13.2 (fetch example rev, "no missing files after update", and the single-line update scenario). Requirement intent is unchanged: still 12 workflows per target, still a rev+hash-only version bump.

## Impact

- `pkgs/openspec-agent-files.nix` — `version`, `rev`, `hash` bump to v1.13.2.
- `overlays/default.nix` — `unstable.openspec` overrideAttrs: `version`, `tag`, `hash`, `pnpmDeps` hash bump to v1.13.2.
- `home-manager/openspec.nix` — unchanged (same 12 workflows, same link entries).
- `pkgs/generate-agent-files.mjs` — unchanged; verify it still bundles and runs against v1.13.2 source.
- `openspec-global-skills` capability — no requirement changes: the global skill/prompt/command set remains the same 12 workflows; only the linked file contents are regenerated.
- Build verification via `make home-build`; the home-manager activation that applies the new files is run by the user.
- No breaking changes to consumers; upstream changelog shows no removals affecting the Pi/OpenCode adapters or the core workflow set.
