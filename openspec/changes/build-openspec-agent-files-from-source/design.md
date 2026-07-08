## Context

Currently, `pkgs/openspec-agent-files/` contains 34 pre-generated files (11 pi skills, 11 pi prompts, 11 opencode skills, 11 opencode commands) produced by running `openspec init --tools pi,opencode --force` and copying the output into the repo. These files are consumed by `pkgs/openspec-agent-files.nix` (a trivial `runCommand` that copies them into a derivation) and symlinked into place by `home-manager/openspec.nix`.

The OpenSpec upstream source (`github.com/Fission-AI/OpenSpec`) contains TypeScript modules (`src/core/templates/workflows/`, `src/core/command-generation/adapters/`) that define the content and formatting of these files. The adapter pattern separates _what_ to generate (workflow templates) from _how_ to format it (per-tool adapters for pi, opencode, claude, cursor, etc.).

The dependency graph for generation is shallow: 12 workflow template modules, 2 adapters, a command-reference transform utility, and a YAML escaping helper — all pure TypeScript with zero external npm dependencies. The entire subgraph can be bundled with esbuild.

## Goals / Non-Goals

**Goals:**
- Generate pi prompts and opencode commands/skills at Nix build time from a pinned OpenSpec source revision
- Eliminate the checked-in `pkgs/openspec-agent-files/` directory
- Preserve the existing `home-manager/openspec.nix` consumption path (`pkgs.openspecAgentFiles`)
- Make version updates a single-line change (pinned `rev`)

**Non-Goals:**
- Generalizing to other OpenSpec adapters (claude, cursor, etc.) — only pi and opencode needed
- Generating `openspec-agent-files` for project-local `.pi/` or `.opencode/` directories (only global paths)
- Replacing `home-manager/openspec.nix` — it continues to consume the same derivation output
- Supporting `openspec init` profiles or delivery filtering — hardcoded to core profile (all workflows) and both delivery modes

## Decisions

### Decision 1: esbuild for TypeScript bundling

**Chosen**: Use `esbuild` (from nixpkgs) to bundle the TypeScript import graph into a single ESM JS file, then run with `node`.

**Alternatives considered**:
- `tsx` / `ts-node` at build time — requires `npm install` of devDependencies from the OpenSpec source, which pulls in the full project dependency tree. Overkill for extracting string constants from 15 files.
- `tsc` + node — slower compile, needs tsconfig resolution.
- Regex extraction — fragile; template strings contain nested backtick expressions that would be non-trivial to parse correctly.

**Rationale**: esbuild strips types and resolves ESM imports in one pass with zero configuration. The subgraph has no runtime npm dependencies, so bundling produces a self-contained JS file that needs only `node`.

### Decision 2: Single build script, not a general-purpose CLI

**Chosen**: A single `pkgs/generate-agent-files.mjs` that imports from the OpenSpec source tree and writes files to `.pi/` and `.opencode/` directories.

**Alternatives considered**:
- Running `openspec init` programmatically — requires the full `openspec` CLI to be built, which has its own complex dependency tree.
- Generic build script accepting tool IDs as arguments — unnecessary complexity for a fixed set of two tools.

**Rationale**: The script is ~40 lines. It directly calls `getSkillTemplates()`, `generateSkillContent()`, `getCommandContents()`, and `generateCommands()` — the same functions `openspec init` uses internally — for pi and opencode only.

### Decision 3: Version pinned to OpenSpec git tags

**Chosen**: Pin `rev` to a git tag (e.g., `v1.5.0`) in `fetchFromGitHub`.

**Rationale**: Tags are the release marker. The `generatedBy` metadata in SKILL.md frontmatter uses this version. Updates require changing one line and updating the `hash`.

### Decision 4: Keep skill files verbatim, no customization

**Chosen**: The generated skill files are byte-for-byte what `openspec init` would produce for pi+opencode with core profile.

**Rationale**: Customization (delivery mode, profile, subset of workflows) adds complexity without benefit for this use case. If needed later, the build script can accept environment variables.

## Risks / Trade-offs

- **[esbuild not in nixpkgs]** → `esbuild` is in nixpkgs at `pkgs.esbuild`. Verified present in nixos-25.11.
- **[Upstream template changes break build]** → The pinned `rev` prevents surprise breakage. Updating the pin is intentional and testable (`make home-build`).
- **[Node.js build dependency]** → `nodejs` is already in the closure. No new runtime dependency; node is only needed at build time.
- **[esbuild bundle size]** → The bundled JS file is ~50KB of template strings. Negligible.
