## Context

This config pins OpenSpec at v1.8.0 in two derivations:

- `pkgs/openspec-agent-files.nix` — a stdenv derivation that fetches the OpenSpec GitHub source at `rev = "v${version}"` and runs the bundled `pkgs/generate-agent-files.mjs` (via esbuild) to emit `.pi/` and `.opencode/` integration files at build time.
- `overlays/default.nix` — the `unstable-packages` overlay overrides `unstable.openspec` (the CLI) with `overrideAttrs`, pinning `version`, `tag`, `hash`, and a separate `pnpmDeps` hash.

`home-manager/openspec.nix` links individual generated files into `~/.pi/agent/skills/`, `~/.pi/agent/prompts/`, `~/.config/opencode/skills/`, and `~/.config/opencode/commands/` — 12 prompts, 12 skills, 12 commands, 12 skills (48 entries), one per core workflow ID.

Verified against the upstream v1.13.2 tree before writing this design:

- The core profile still emits the same 12 workflows (`getSkillTemplates` in `src/core/shared/skill-generation.ts` lists the same 12 entries; `feedback`/`project-root`/`store-selection` template modules are not in the core set). No new prompt/skill/command files → no `home-manager/openspec.nix` changes.
- All six modules imported by `pkgs/generate-agent-files.mjs` (`skill-generation.ts`, adapters `pi.ts`/`opencode.ts`, `generator.ts`, `command-references.ts`, `invocation.ts`) still exist at v1.13.2 with the same exported symbols and compatible signatures.

New upstream tool targets since v1.8.0 (Command Code v1.9.0, Zed v1.10.0, SourceCraft v1.12.0) are not wired into this config.

## Goals / Non-Goals

**Goals:**
- Move the pinned OpenSpec version from v1.8.0 to v1.13.2 in both the CLI override and the agent-files derivation, keeping them in sync.
- Preserve the "version update is a single-line change per derivation" property for future bumps.
- Verify the build with `make home-build` only; never run `make home`.

**Non-Goals:**
- Wiring in new tool targets (Command Code, Zed, SourceCraft, `.agents/skills`). Out of scope.
- Changing `pkgs/generate-agent-files.mjs` (adapter selection, import paths) — pre-verified compatible; only revisit if the build proves otherwise.
- Changing `home-manager/openspec.nix` link entries — the workflow set is unchanged.
- Adopting the `openspec update` self-updater as the source of truth — Nix remains the update mechanism.
- Running the home-manager activation; the user runs `make home`.

## Decisions

**Decision 1 — Keep two pinning sites, bump both in lockstep.**
Same rationale as the v1.5.0→v1.8.0 update: the CLI is an npm/pnpm package (`unstable.openspec` requires `pnpmDeps`) while the agent-files derivation is a source-only stdenv build; the npm package does not ship the `src/core/...` modules the generator imports, so deriving agent files from the CLI package is not possible. A shared `rev`/`hash` variable remains rejected — the two derivations use different hash kinds (fetchFromGitHub vs. fetchFromGitHub + fetchPnpmDeps).

**Decision 2 — Update hashes by letting Nix re-fetch, not by hardcoding guesses.**
For each affected hash (`fetchFromGitHub` in both derivations and `fetchPnpmDeps` in the overlay), set the hash to the fake hash (`lib.fakeHash` / empty string), run the build so Nix reports the correct hash, then paste it in. Same workflow used for the existing pins.

**Decision 3 — No `home-manager/openspec.nix` edits.**
Unlike the v1.8.0 update (which added the 12th `update` workflow), v1.13.2 adds no core workflows, so the 48 link entries stay as they are. The regenerated file contents flow through the existing links automatically on the next home-manager activation.

**Decision 4 — Do not touch `pkgs/generate-agent-files.mjs`.**
Pre-verified that all imports resolve at v1.13.2 with compatible exports (see Context). Treat build failure as the signal to revisit, not speculation.

## Risks / Trade-offs

- [A transitive import of the bundled modules changed shape between v1.8.0 and v1.13.2 even though the direct imports are stable] → esbuild bundling or the node run fails. Mitigation: `make home-build` surfaces it; diff the upstream module and adjust `generate-agent-files.mjs` accordingly.
- [`pnpmDeps` hash or pnpm major version requirement changed upstream] → The overlay pins `pnpm = final'.pnpm_11`. Mitigation: if `fetchPnpmDeps` fails on lockfile version, inspect the v1.13.2 lockfile and bump the pnpm input.
- [nixpkgs-unstable's own `openspec` package changes its build in a way the override depends on] → The override reuses `oldAttrs.pname` and nixpkgs' build recipe with a replaced `src`. Mitigation: if the override stops evaluating after a flake update, re-check nixpkgs' `openspec` derivation; out of scope for this change (flake inputs are not bumped here).
- [Generated file contents change workflow behavior for agents (new guidance, stricter task rules in v1.13.x)] → Desired; this is the point of the update. No spec change needed because the specs assert file sets and frontmatter shape, not prose content.

## Migration Plan

1. Bump `version`/`rev`/`hash` in `pkgs/openspec-agent-files.nix` to v1.13.2 (re-fetch hash via Nix fake-hash workflow).
2. Bump `version`/`tag`/`hash`/`pnpmDeps` hash in the `unstable.openspec` overrideAttrs in `overlays/default.nix` (same re-fetch workflow).
3. Run `make home-build`; fix hash/import issues if they surface.
4. Confirm the built derivation still emits exactly 12 files per target and that `openspec --version` from the built CLI reports 1.13.2.
5. Stop. The user runs `make home` to activate.

Rollback: revert the two edited files; the v1.8.0 hashes are already known. No data migration and no flake input change required.
