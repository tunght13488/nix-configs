## Context

The user's primary coding agent is pi, which explicitly does not support MCP. The user also has `programs.claude-code` and `programs.opencode` enabled via home-manager but primarily works inside pi running in herdr. codebase-memory-mcp provides a high-performance knowledge graph for code discovery (158 tree-sitter languages, hybrid LSP for 11 including PHP), but its native `install` command only configures MCP-based agents. For pi, the CLI mode (`codebase-memory-mcp cli <tool> '<json>'`) is the integration path.

The nix-configs repo follows the [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs) structure: `pkgs/` for custom packages, `overlays/` for nixpkgs overlays, `modules/home-manager/` for reusable home-manager modules. This change adds one package and one module, fitting the existing architecture.

The binary persists indexes to `~/.cache/codebase-memory-mcp/` (SQLite). This is user cache, not Nix-managed, and should not be touched by the module.

## Goals / Non-Goals

**Goals:**
- Install the codebase-memory-mcp binary declaratively via Nix
- Provide a pi skill that teaches the agent to use CLI tools for code discovery, matching the same workflow guidance the native `install` writes for Claude Code/OpenCode
- Wrap everything in a `mkEnableOption` + `mkIf` home-manager module so it can be toggled
- Use the pre-built portable binary (single static file, no runtime deps)

**Non-Goals:**
- MCP integration for pi (pi has no MCP support, and building an extension bridge is out of scope)
- MCP configuration for Claude Code or OpenCode (user can run `codebase-memory-mcp install` separately if desired; declarative MCP config for those agents conflicts with the home-manager modules managing their JSON files)
- Building from source (the binary has 158 vendored tree-sitter grammars; pre-built is pragmatic)
- Graph visualization UI variant (standard binary only; UI can be added later if needed)
- Auto-indexing or background watcher configuration (the skill teaches the agent to index explicitly)

## Decisions

### 1. Pre-built binary over from-source

**Choice**: `fetchurl` from GitHub releases (`codebase-memory-mcp-linux-amd64-portable.tar.gz`, v0.9.0).

**Alternatives considered**:
- Building from source via `stdenv.mkDerivation`: The repo has 158 vendored tree-sitter grammars in a custom build system. Nixpkgs has tree-sitter infrastructure but adapting it would be a complex, fragile derivation. Not worth the effort for a single-user config.
- Non-portable build (`linux-amd64.tar.gz` without `-portable`): Dynamically links glibc 2.38+. The portable variant is fully static — it works on any Linux kernel via syscalls. This is exactly what we want for Nix, avoiding glibc compatibility issues.

**Rationale**: The binary is a single static file with zero runtime dependencies (embedded SQLite, embedded tree-sitter grammars, embedded embeddings model). `fetchurl` + `installPhase = "cp $src/codebase-memory-mcp $out/bin/"` is trivial and reliable. The hash pins the exact binary. Checksums are verified from GitHub releases.

### 2. Skill file lives in the package, not the module

**Choice**: The SKILL.md is part of the Nix package derivation (`$out/share/pi/skills/codebase-memory/SKILL.md`), and the home-manager module symlinks to it via `home.file."...".source`. This follows the existing pattern of `pkgs/openspec-agent-files.nix` and `pkgs/herdr-agent-files.nix`.

**Alternatives considered**:
- Inline the skill content as a string in the module: Couples content to config, makes the module file large and hard to edit. The package approach keeps the skill content as a separate file alongside the binary.

**Rationale**: All pi skills in this repo (openspec, herdr) are built as packages and symlinked. codebase-memory-mcp should follow the same convention for consistency and editability.

### 3. Home-manager module structure

**Choice**: New file `modules/home-manager/codebase-memory-mcp.nix` following the existing pattern of modules in `modules/home-manager/` (e.g., `ngrok.nix`).

The module:
- `mkEnableOption "codebase-memory-mcp"`
- `home.packages = [ pkgs.codebase-memory-mcp ]` when enabled
- `home.file.".pi/agent/skills/codebase-memory/SKILL.md".source = "${pkgs.codebase-memory-mcp}/share/pi/skills/codebase-memory/SKILL.md"`

**Alternatives considered**:
- Extend `home-manager/ai.nix` directly: Would couple the codebase-memory config to the general AI config, making it harder to toggle independently. A dedicated module is cleaner.

### 4. Pi skill content

**Choice**: A single `SKILL.md` bundled in the package (at `pkgs/codebase-memory-mcp/skill.md`) and installed to `$out/share/pi/skills/codebase-memory/SKILL.md`. It replicates the knowledge from the Claude Code skill + SessionStart hook that the native `install` writes, adapted for CLI syntax.

Content derived from the upstream source (`src/cli/cli.c`):
- Code discovery protocol (from SessionStart hook): "ALWAYS prefer graph tools over grep for code discovery"
- Decision matrix (from Claude Code skill): what tool for what question
- Exploration workflow (from Claude Code skill): index → schema → search → snippet
- Tracing workflow: search → trace_path → detect_changes
- Quality analysis: dead code, high fan-out/fan-in
- Gotchas (from Claude Code skill): 200-row query cap, trace needs exact names, pagination
- All 14 CLI tool commands with JSON argument examples

**Alternatives considered**:
- Multiple skill files (like Claude Code gets): Pi skills are markdown files; a single well-organized file is clearer than fragmented ones since pi has no hook system to trigger them conditionally.
- CLI wrapper script: A shell script wrapping the binary with shorter commands (e.g., `cbm-search` instead of `codebase-memory-mcp cli search_graph`). This adds indirection; the skill can use the full commands directly. A wrapper can be added later if verbosity is a problem.

### 5. No flake overlay

**Choice**: The package is defined in `pkgs/` and not added to an overlay. It's consumed directly by the home-manager module via `pkgs.codebase-memory-mcp` (which works because `pkgs/` is included via `callPackage` in the flake).

**Rationale**: This is a leaf package with no consumers outside this repo. Overlays add indirection without benefit here.

## Risks / Trade-offs

- **[Binary trust]** The pre-built binary runs with full user permissions, reads source code, and writes to `~/.cache/`. While the project is MIT-licensed and has 28K+ stars, signature verification, and VirusTotal scanning, there's no Nix build reproducibility. → Mitigation: The binary only processes local files; the `CBM_ALLOWED_ROOT` env var can restrict indexing scope if needed. For the user's threat model (local dev tooling on a single-machine NixOS setup), this is acceptable.

- **[Cache not Nix-managed]** Indexes in `~/.cache/codebase-memory-mcp/` persist across Nix rebuilds and aren't garbage-collected. This is intentional — the knowledge graph is user data, not Nix artifacts. → Mitigation: Document this. The binary's own `update` and `uninstall` commands manage the cache.

- **[Version pinning]** The binary version is hardcoded in the derivation (v0.9.0). Updates require manual hash changes. → Mitigation: This is standard for `fetchurl` derivations. The in-binary `codebase-memory-mcp update` is an alternative update path, but it's imperative (not Nix-managed). For now, accept the tradeoff.

- **[Pi CLI verbosity]** The CLI commands are verbose (`codebase-memory-mcp cli search_graph '{"name_pattern":".*Foo.*"}'`). → Mitigation: The skill should include a note that the agent can create a shell alias or function if verbosity becomes an issue. Monitor in practice.
