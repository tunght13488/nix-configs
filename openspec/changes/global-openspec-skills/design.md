## Context

OpenSpec provides a CLI (`openspec`) and agent integration files (skills, prompts, commands) for spec-driven development. The CLI is already installed via `pkgs.unstable.openspec` in `home-manager/home.nix`. The agent integration files currently exist only at the project level in `nix-configs/.pi/` (Pi skills/prompts; OpenCode not configured at all).

Both Pi and OpenCode follow the [Agent Skills standard](https://agentskills.io) for skill discovery and support global config directories:
- Pi: `~/.pi/agent/skills/` and `~/.pi/agent/prompts/`
- OpenCode: `~/.config/opencode/skills/` and `~/.config/opencode/commands/`

The skill files (`SKILL.md`) are identical between agents. Only the companion files differ: Pi uses prompt templates (`.pi/prompts/`), OpenCode uses command files (`.opencode/commands/`).

The source of truth for these files is `openspec init --tools pi,opencode`, which generates all files in a target project directory.

## Goals / Non-Goals

**Goals:**
- Generate OpenSpec skill, prompt, and command files from the current `pkgs.unstable.openspec` version at build time
- Deploy them to global Pi and OpenCode config directories via home-manager
- Link individual files (not whole directories) to coexist with other global skills
- Keep the approach consistent with existing nix-configs patterns (derivations in `pkgs/`, modules in `home-manager/`)

**Non-Goals:**
- Managing these files outside Nix/home-manager
- Using directory-level symlinks that would shadow other global skills
- Modifying existing project-level OpenSpec files in nix-configs
- Installing OpenSpec for other agents (Claude, Codex, etc.)

## Decisions

### Decision 1: Nix derivation over shell script or checked-in files

**Rationale:** A derivation that runs `openspec init` at build time automatically stays in sync with the OpenSpec version pinned in the flake. When `pkgs.unstable.openspec` updates, the files regenerate on next `make home`. No manual regeneration step, no stale committed files.

**Alternatives considered:**
- Shell script — rejected; manual step, easy to forget after openspec updates
- Checked-in generated files — rejected; manual commit step, risk of drift
- IFD (import from derivation) — rejected; unnecessary complexity, the derivation approach avoids IFD entirely

### Decision 2: Individual file linking over directory symlinks

**Rationale:** Linking individual files (`home.file.".pi/agent/skills/openspec-apply-change/SKILL.md".source = ...`) rather than the whole skills directory allows other global skills to coexist in the same directory. A directory symlink would replace the entire `skills/` directory, shadowing any other globally installed skills.

**Alternatives considered:**
- Directory symlink — rejected; conflicts with other global skills
- `lib.mapAttrs'` dynamic mapping — rejected; the file list is small and stable (16 entries), explicit entries are clearer and type-safe

### Decision 3: Separate home-manager module (`home-manager/openspec.nix`)

**Rationale:** Follows the existing convention of one module per concern (`ai.nix`, `git.nix`, `php.nix`, etc.). Keeps the implementation self-contained and importable. The existing `home-manager/ai.nix` handles Pi's AGENTS.md and OpenCode's config — adding 16 `home.file` entries there would bloat it.

**Alternatives considered:**
- Inline in `ai.nix` — rejected; would make the file too long and mix unrelated concerns
- Inline in `home.nix` — rejected; even worse, `home.nix` is an imports hub, not for implementation

### Decision 4: New package in `pkgs/` rather than inline derivation

**Rationale:** Follows the convention in `AGENTS.md`: custom packages go in `pkgs/` and are exposed via overlays. The derivation is a self-contained build step — putting it in `pkgs/` makes it testable independently via `nix build .#openspecAgentFiles`.

**Alternatives considered:**
- Inline let-binding in the module — rejected; less reusable, harder to test
- Overlay package only (no `pkgs/` file) — rejected; `pkgs/` files are the project convention

## Risks / Trade-offs

- [Build dependency] `openspec init` needs a writable directory to generate files — Mitigation: run in `$TMPDIR` within the derivation
- [New skills] If future OpenSpec adds skills, the explicit file entries need updating — Mitigation: the derivation auto-generates new files; missing `home.file` entries surface as missing files at build time
- [Name collision] If a project already has OpenSpec skills in `.pi/skills/`, the global ones are loaded first by Pi — Mitigation: no conflict; user can remove project-local skills to rely on global
- [Build time] Runs `openspec init` on every home-manager build — Mitigation: Nix caches the derivation output; only rebuilds when openspec or the derivation changes
