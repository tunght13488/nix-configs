## 1. Regenerate agent files from openspec CLI

- [x] 1.1 Run `openspec init --tools pi,opencode --force` in a temp directory to generate all 11 workflow files
- [x] 1.2 Replace contents of `pkgs/openspec-agent-files/.pi/` with generated Pi output (skills + prompts)
- [x] 1.3 Replace contents of `pkgs/openspec-agent-files/.opencode/` with generated OpenCode output (skills + commands)
- [x] 1.4 Run `git diff pkgs/openspec-agent-files/` to verify changes are expected (existing 5 unchanged or improved, 6 new additions)

## 2. Update home-manager module

- [x] 2.1 Add `home.file` entries in `home-manager/openspec.nix` for the 6 missing Pi skills (bulk-archive-change, continue-change, ff-change, new-change, onboard, verify-change)
- [x] 2.2 Add `home.file` entries for the 6 missing Pi prompts (opsx-bulk-archive, opsx-continue, opsx-ff, opsx-new, opsx-onboard, opsx-verify)
- [x] 2.3 Add `xdg.configFile` entries for the 6 missing OpenCode skills
- [x] 2.4 Add `xdg.configFile` entries for the 6 missing OpenCode commands

## 3. Update main spec

- [x] 3.1 Replace `openspec/specs/openspec-global-skills/spec.md` with the full 11-workflow requirements from the delta spec

## 4. Remove project-local OpenSpec skills

- [x] 4.1 Delete `.pi/skills/openspec-*/` directories (all 11) — they're now redundant with global deployment
- [x] 4.2 Verify with `ls .pi/skills/` that only non-OpenSpec skills remain (directory empty)

## 5. Verify

- [x] 5.1 Run `make home-build` to verify the home-manager configuration evaluates
- [x] 5.2 Run `make format` to format all changed Nix files
