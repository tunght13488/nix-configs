## Context

OpenSpec provides a CLI (`openspec`) and agent integration files (skills, prompts, commands) for spec-driven development. The CLI is already installed via `pkgs.unstable.openspec` in `home-manager/home.nix`. The agent integration files currently exist only at the project level in `nix-configs/.pi/` (Pi skills/prompts; OpenCode not configured at all).

Both Pi and OpenCode follow the [Agent Skills standard](https://agentskills.io) for skill discovery and support global config directories:
- Pi: `~/.pi/agent/skills/` and `~/.pi/agent/prompts/`
- OpenCode: `~/.config/opencode/skills/` and `~/.config/opencode/commands/`

The skill files (`SKILL.md`) are identical between agents. Only the companion files differ: Pi uses prompt templates (`.pi/prompts/`), OpenCode uses command files (`.opencode/commands/`).

The source of truth for these files is `openspec init --tools pi,opencode`, which generates all files in a target project directory. Files are pre-generated and checked into `pkgs/openspec-agent-files/` to avoid running `openspec init` inside the Nix sandbox (Node.js network initialization hangs when sandboxed).

OpenSpec 1.4.1 generates 5 skills (not 4): includes `openspec-sync-specs` and `opsx-sync` as a newer addition.

## Goals / Non-Goals

**Goals:**
- Store OpenSpec skill, prompt, and command files in the nix-configs repo for reproducibility
- Deploy them to global Pi and OpenCode config directories via home-manager
- Link individual files (not whole directories) to coexist with other global skills
- Keep the approach consistent with existing nix-configs patterns (derivations in `pkgs/`, modules in `home-manager/`)

**Non-Goals:**
- Running `openspec init` inside the Nix sandbox (hangs due to Node.js network initialization without network access)
- Auto-generating files at build time (files are pre-generated and checked in; regenerate manually when openspec updates)
- Using directory-level symlinks that would shadow other global skills
- Modifying existing project-level OpenSpec files in nix-configs
- Installing OpenSpec for other agents (Claude, Codex, etc.)

## Decisions

### Decision 1: Checked-in generated files with thin Nix derivation wrapper

**Rationale:** `openspec init` hangs in the Nix sandbox (Node.js attempts network access during initialization). Instead, files are generated once by running `openspec init --tools pi,opencode --force` and checked into `pkgs/openspec-agent-files/`. The derivation is a thin wrapper that copies these files to `$out`. To regenerate, run `openspec init` outside Nix and copy the output.

**Alternatives considered:**
- Running `openspec init` at build time — rejected; hangs in sandbox
- Writing SKILL.md content inline in the derivation — rejected; verbose, drift-prone
- Shell script outside Nix — rejected; no Nix reproducibility
- IFD — rejected; adds complexity for no benefit

### Decision 2: Individual file linking over directory symlinks

**Rationale:** Linking individual files (`home.file.".pi/agent/skills/openspec-apply-change/SKILL.md".source = ...`) rather than the whole skills directory allows other global skills to coexist in the same directory. A directory symlink would replace the entire `skills/` directory, shadowing any other globally installed skills.

**Alternatives considered:**
- Directory symlink — rejected; conflicts with other global skills
- `lib.mapAttrs'` dynamic mapping — rejected; the file list is small and stable (20 entries), explicit entries are clearer and type-safe

### Decision 3: Separate home-manager module (`home-manager/openspec.nix`)

**Rationale:** Follows the existing convention of one module per concern (`ai.nix`, `git.nix`, `php.nix`, etc.). Keeps the implementation self-contained and importable.

**Alternatives considered:**
- Inline in `ai.nix` — rejected; would make the file too long and mix unrelated concerns
- Inline in `home.nix` — rejected; even worse, `home.nix` is an imports hub, not for implementation

### Decision 4: Pre-generated files in `pkgs/openspec-agent-files/`

**Rationale:** The generated directory structure is placed alongside the derivation file in `pkgs/`. The derivation references it via `./openspec-agent-files/`, making the relative path stable and Nix-compatible without IFD.

**Alternatives considered:**
- Placing in a top-level `dotfiles/` directory — rejected; derivation would need `../` path reference which is fragile
- Placing in `openspec/` directory — rejected; that dir is for the OpenSpec tool itself (changes, specs), not for generated outputs

## Risks / Trade-offs

- [Staleness] Checked-in files may drift from the openspec CLI version — Mitigation: documented regeneration command in the derivation header; openspec CLI version is pinned via flake
- [New skills] If future OpenSpec adds skills, the explicit file entries need updating — Mitigation: missed files surface as build errors at `make home-build` time
- [Name collision] If a project already has OpenSpec skills in `.pi/skills/`, the global ones are loaded first by Pi — Mitigation: no conflict; user can remove project-local skills to rely on global
- [File count] 20 `home.file`/`xdg.configFile` entries is verbose but straightforward — Mitigation: each entry is one line with a clear pattern; easy to add/remove
