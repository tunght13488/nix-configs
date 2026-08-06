## Context

This config pins OpenSpec at v1.5.0 in two derivations:

- `pkgs/openspec-agent-files.nix` — a stdenv derivation that fetches the OpenSpec GitHub source at a hardcoded `rev = "v${version}"` and runs the bundled `pkgs/generate-agent-files.mjs` (via esbuild) to emit `.pi/` and `.opencode/` integration files at build time.
- `overlays/default.nix` — the `unstable-packages` overlay overrides `unstable.openspec` (the CLI) with `overrideAttrs`, pinning `version`, `tag`, `hash`, and a separate `pnpmDeps` hash.

`home-manager/openspec.nix` then links individual generated files into `~/.pi/agent/skills/`, `~/.pi/agent/prompts/`, `~/.config/opencode/skills/`, and `~/.config/opencode/commands/` using `${openspecAgentFiles}/...` sources. It currently links 11 Pi prompts, 11 Pi skills, 11 OpenCode commands, and 11 OpenCode skills (44 entries), one per core workflow ID.

Upstream v1.6.0 adds a new `/opsx:update` planning workflow → a 12th prompt/skill/command. v1.6.0 also tightens generated-skill permissions (frontmatter pre-approves the OpenSpec CLI). v1.7.0 adds an `openspec update` self-updater and per-operation guidance in `openspec instructions apply|archive`. v1.8.0 adds the `agents` (`.agents/skills/`) target and `retire_capabilities` archive handling. The new tool targets (Oh My Pi `.omp`, TRAE, `agents`, MiniMax, Rovo, Copilot cloud) are not wired into this config.

## Goals / Non-Goals

**Goals:**
- Move the pinned OpenSpec version from v1.5.0 to v1.8.0 in both the CLI override and the agent-files derivation, keeping them in sync.
- Surface the new `update` workflow globally for both Pi and OpenCode so the 12th prompt/skill/command is linked.
- Preserve the "version update is a single-line change per derivation" property for future bumps.
- Verify the build with `make home-build` only; never run `make home`.

**Non-Goals:**
- Wiring in new v1.6–1.8 tool targets (`.omp`, TRAE, `.agents/skills`, MiniMax, Rovo, Copilot cloud). Out of scope.
- Changing `pkgs/generate-agent-files.mjs` adapter selection (still Pi + OpenCode only).
- Adopting the v1.7.0 `openspec update` self-updater as the source of truth — Nix remains the update mechanism.
- Running the home-manager activation; the user runs `make home`.

## Decisions

**Decision 1 — Keep two pinning sites, bump both in lockstep.**
The CLI and the agent-files derivation are intentionally separate because one is an npm/pnpm package (`unstable.openspec` requires `pnpmDeps`) and the other is a source-only stdenv build. Alternatives considered: (a) derive the agent files from the installed `openspec` package output rather than re-fetching source — rejected because the npm package does not ship the `src/core/...` adapter/template modules the generator imports. (b) Single shared `rev`/`hash` variable imported by both — tempting but the two derivations have different hash kinds (source tarball fetchFromGitHub hash vs. source hash + pnpmDeps fetchPnpmDeps hash), and a shared attrset would obscure that the CLI needs its own `pnpmDeps` bump. Keep them separate but document that both must move together.

**Decision 2 — Update hashes by letting Nix re-fetch, not by hardcoding guesses.**
For each affected hash (`fetchFromGitHub` in both derivations and `fetchPnpmDeps` in the overlay), set the hash to the libfakehash and run `nix build`/`nix-prefetch` so Nix reports the correct hash, then paste it in. This avoids hash-mismatch iteration by hand and is the same workflow the existing v1.5.0 pins were produced with.

**Decision 3 — Add the `update` workflow links at the end of each block in `home-manager/openspec.nix`.**
Mirror the existing per-block pattern: append `opsx-update.md` after `opsx-verify.md` in the Pi prompts block, `openspec-update-change/SKILL.md` in the Pi skills block, the corresponding OpenCode command, and the OpenCode skill. This keeps the "one entry per workflow" grouping intact and makes the "exactly 12" counts testable.

**Decision 4 — Do not regenerate the checked-in files; keep the build-time generation model.**
The derivation already generates files at build time from source (per `openspec-agent-generation` spec), so there are no checked-in generated files to update. The only file-list change is the four new link entries in `home-manager/openspec.nix`.

## Risks / Trade-offs

- [v1.8.0 generator import paths moved] → `pkgs/generate-agent-files.mjs` imports `./src/core/shared/skill-generation.ts`, `./src/core/command-generation/adapters/pi.ts`, `./src/core/command-generation/adapters/opencode.ts`, `./src/core/command-generation/generator.ts`, `./src/utils/command-references.ts`. If any of these moved or were renamed in v1.6–1.8, esbuild bundling fails. Mitigation: after bumping, run `make home-build`; if it fails on import resolution, diff the source tree for the renamed module and update the import paths in `generate-agent-files.mjs`.
- [`openspec update` self-updater (v1.7.0) could drift the installed binary out of sync with the Nix pin] → The self-updater writes outside Nix. Mitigation: keep relying on Nix as the update mechanism; do not run `openspec update` interactively. Document in the spec that Nix is the source of truth.
- [New generated file permissions frontmatter changes behavior of other agents] → Generated skills now pre-approve `openspec:*` tools; this is desirable (fewer approval prompts) and matches the existing `allowed-tools: Bash(openspec:*)` frontmatter already asserted in the spec, so no spec change for permissions beyond confirming it still holds.
- [`pnpmDeps` hash changes between pnpm versions] → The overlay pins `pnpm = final'.pnpm_11`. If v1.8.0 bumps the required pnpm, `fetchPnpmDeps` may fail. Mitigation: if `make home-build` fails on pnpm lockfile version, inspect the v1.8.0 lockfile and bump the pnpm input if needed.

## Migration Plan

1. Bump `version`/`rev`/`hash` in `pkgs/openspec-agent-files.nix` to v1.8.0 values (re-fetch hashes via Nix).
2. Bump `version`/`tag`/`hash`/`pnpmDeps` hash in the `unstable.openspec` overrideAttrs in `overlays/default.nix`.
3. Add the four `update` workflow link entries to `home-manager/openspec.nix`.
4. Run `make home-build`; fix import-path/hash issues if they surface.
5. Stop. The user runs `make home` to activate.

Rollback: revert the three edited files; the v1.5.0 hashes are already known. No data migration and no flake input change required (this uses `unstable.openspec`, not a dedicated flake input).

## Open Questions

- Does v1.8.0 name the new workflow skill `openspec-update-change` (matching the existing `<verb>-change` naming) or something else? Confirm by inspecting the generated `.pi/skills/` directory after the first successful build before finalizing the `home-manager/openspec.nix` link entry names.
- Should the `agents` (`.agents/skills/`) target also be wired in now that this config's own `AGENTS.md` files are agent-aware? Deferred — out of scope for this change; can be a follow-up change.