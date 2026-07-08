## Why

The pi and opencode agent integration files (skills, prompts, commands) are currently checked into the repo as pre-generated artifacts from `openspec init`. This creates a maintenance burden: updating to a new OpenSpec version requires manually regenerating, diffing, and committing ~34 files. A Nix derivation that builds directly from the OpenSpec source eliminates this manual step and pins the generation logic to the exact source revision used.

## What Changes

- Replace `pkgs/openspec-agent-files/` (checked-in generated directory) with a derivation that fetches the OpenSpec source at a pinned version and generates the agent files at build time
- Add a small Node.js build script (`pkgs/generate-agent-files.mjs`) that imports the adapter and template modules from the OpenSpec source tree, then outputs `.pi/` and `.opencode/` file trees
- Use `esbuild` as a build input to bundle the TypeScript modules into a single executable JS file
- `home-manager/openspec.nix` continues to consume `pkgs.openspecAgentFiles` — no changes needed to the symlink layer
- Delete the checked-in `pkgs/openspec-agent-files/` directory

## Capabilities

### New Capabilities

- `openspec-agent-generation`: Build-time generation of pi prompt templates and opencode slash commands from the upstream OpenSpec TypeScript source, replacing checked-in pre-generated files with a pinned-source derivation.

### Modified Capabilities

None — the existing OpenSpec integration modules (`home-manager/openspec.nix`) consume the same derivation output path.

## Impact

- `pkgs/openspec-agent-files.nix`: Rewritten from `runCommand` (copies checked-in files) to `stdenv.mkDerivation` (fetches source, runs esbuild)
- `pkgs/openspec-agent-files/`: **Deleted** — entire checked-in directory removed
- `pkgs/generate-agent-files.mjs`: **New file** — build script that imports adapters and templates from OpenSpec source
- No changes to `home-manager/openspec.nix`, `home-manager/home.nix`, or overlay wiring
