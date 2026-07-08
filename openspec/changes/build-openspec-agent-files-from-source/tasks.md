## 1. Create build script

- [ ] 1.1 Create `pkgs/generate-agent-files.mjs` that imports adapters and templates from OpenSpec source, generates `.pi/` and `.opencode/` output trees
- [ ] 1.2 Verify the script can be bundled with `esbuild --bundle --platform=node --format=esm`

## 2. Rewrite derivation

- [ ] 2.1 Rewrite `pkgs/openspec-agent-files.nix` to use `stdenv.mkDerivation` with `fetchFromGitHub` (pinned to `v1.5.0`), `esbuild` and `nodejs` as native build inputs
- [ ] 2.2 Set `OPENSPEC_VERSION` environment variable in derivation for `generatedBy` metadata
- [ ] 2.3 Bundle and run the build script in `buildPhase`, copy `.pi/` and `.opencode/` to `$out` in `installPhase`

## 3. Remove old artifacts

- [ ] 3.1 Delete `pkgs/openspec-agent-files/` directory (checked-in generated files)
- [ ] 3.2 `git add` the new files so Nix can resolve them

## 4. Verify

- [ ] 4.1 Run `make home-build` to confirm derivation builds and all 34 files are produced
- [ ] 4.2 Spot-check one pi prompt file for correct frontmatter and `/opsx-` references
- [ ] 4.3 Spot-check one skill file for Agent Skills YAML frontmatter including `generatedBy`

## 5. Format and commit

- [ ] 5.1 Run `make format` on changed Nix files
- [ ] 5.2 Commit with message describing the change
