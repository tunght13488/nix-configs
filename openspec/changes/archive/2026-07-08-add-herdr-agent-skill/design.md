## Context

The herdr flake input (`github:ogulcancelik/herdr/v0.7.3`) includes an agent skill file at the repo root (`SKILL.md`) that teaches coding agents how to interact with herdr workspaces, tabs, panes, and CLI commands. This file is currently installed via `npx skills add ogulcancelik/herdr --skill herdr -g` — an npm-based method outside the Nix config.

The repo already has a pattern for Nix-managed agent skills: `pkgs/openspec-agent-files` → overlay → `home-manager/openspec.nix` links files into `~/.pi/` and `~/.config/opencode/`. This change replicates that pattern for the herdr skill.

## Goals / Non-Goals

**Goals:**
- Derive the herdr agent skill file from the existing `inputs.herdr` flake input
- Make the skill available to Pi and OpenCode globally via home-manager
- Follow the same derivation + overlay + home-manager module pattern as `openspec-agent-files`
- Add skill linking to the existing `home-manager/herdr.nix` (co-locating herdr concerns)

**Non-Goals:**
- Do not modify the herdr config bootstrapping logic already in `herdr.nix`
- Do not create a separate home-manager module file — extend `herdr.nix` directly
- Do not change the herdr flake input pin (v0.7.3 already contains `SKILL.md`)
- Do not handle other agents beyond Pi and OpenCode
- Do not replace or remove the existing `npx skills` installation

## Decisions

### Decision 1: Derivation structure — `pkgs/herdr-agent-files.nix`

Follows the exact pattern of `pkgs/openspec-agent-files.nix`: a `runCommand` derivation that copies files from a source into `$out` with the expected directory layout. The source is `${inputs.herdr.outPath}/SKILL.md`.

**Alternatives considered:**
- `fetchurl` from a raw GitHub URL — rejected because it bypasses the flake lock, creating an untracked dependency
- Direct `home.file.source = "${inputs.herdr.outPath}/SKILL.md"` — rejected because it wouldn't survive garbage collection; a derivation ensures the source path stays in the store

### Decision 2: Output layout mirrors agent conventions

The derivation produces:
```
$out/.pi/skills/herdr/SKILL.md
$out/.opencode/skills/herdr/SKILL.md
```

This matches the directory conventions used by Pi (`~/.pi/agent/skills/<name>/SKILL.md`) and OpenCode (`~/.config/opencode/skills/<name>/SKILL.md`), and mirrors the layout in `openspec-agent-files`.

**Alternatives considered:**
- Single file at `$out/SKILL.md` with home-manager doing the directory structure — rejected because it's less self-documenting and diverges from the established pattern

### Decision 3: Extend `herdr.nix` rather than creating a new module

All herdr-related home-manager configuration lives in one file: config bootstrapping (existing) plus skill linking (new). The section is clearly separated with a comment header.

**Alternatives considered:**
- New file `home-manager/herdr-skill.nix` — rejected; adds unnecessary fragmentation for what is conceptually "herdr setup"
- Fold into `openspec.nix` — rejected; herdr is unrelated to OpenSpec

### Decision 4: Overlay registration in `additions`

Registered as `herdrAgentFiles` (mirroring `openspecAgentFiles`) in the `additions` overlay. The derivation receives `inputs.herdr.outPath` as a parameter.

**Alternatives considered:**
- Direct `callPackage` without overlay — already done for `openspecAgentFiles`, consistency wins

## Risks / Trade-offs

- **If the herdr flake input is updated to a version without `SKILL.md`**: The derivation fails at build time (clear, hard error). Mitigation: the flake lock pins a specific revision; manual updates are deliberate.
- **Skill file at repo root (not `skills/herdr/`)**: This is an unusual layout compared to the `skills/` convention. But it's what herdr ships, so the derivation reflects reality.
- **Redundant with existing `npx skills` install**: Both will coexist until the `npx skills` version is manually removed. No conflict — same file content, same target paths.
