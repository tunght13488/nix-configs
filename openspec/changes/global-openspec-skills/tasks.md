## 1. Create the Nix derivation

- [ ] 1.1 Create `pkgs/openspec-agent-files.nix` with a `stdenv.mkDerivation` that runs `openspec init --tools pi,opencode --force` and installs the generated `.pi/` and `.opencode/` directories to `$out`
- [ ] 1.2 Expose the derivation via `overlays/default.nix` as `openspecAgentFiles`
- [ ] 1.3 Verify the derivation builds: `nix build .#openspecAgentFiles` and inspect `result/`

## 2. Create the home-manager module

- [ ] 2.1 Create `home-manager/openspec.nix` with `home.file` entries linking the 4 Pi skill directories and 4 Pi prompt files to `~/.pi/agent/skills/` and `~/.pi/agent/prompts/`
- [ ] 2.2 Add `xdg.configFile` entries in the same module linking the 4 OpenCode skill directories to `~/.config/opencode/skills/` and 4 command files to `~/.config/opencode/commands/`
- [ ] 2.3 Use `lib.mkDefault` or similar guarding so users can override individual entries if needed
- [ ] 2.4 Import `home-manager/openspec.nix` in `home-manager/home.nix`

## 3. Build and verify

- [ ] 3.1 Run `make home-build` and confirm no evaluation errors
- [ ] 3.2 Verify all 16 files exist in the Nix store at the correct paths
- [ ] 3.3 Check that individual file links work alongside other potential global skills (not shadowing the directory)
