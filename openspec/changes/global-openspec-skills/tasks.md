## 1. Create the Nix derivation

- [x] 1.1 Create `pkgs/openspec-agent-files.nix` with a `runCommand` that copies checked-in generated files from `pkgs/openspec-agent-files/` to `$out`
- [x] 1.2 Expose the derivation via `overlays/default.nix` as `openspecAgentFiles`
- [x] 1.3 Verify the derivation builds via `make home-build`

## 2. Create the home-manager module

- [x] 2.1 Create `home-manager/openspec.nix` with `home.file` entries linking the 5 Pi skill directories and 5 Pi prompt files to `~/.pi/agent/skills/` and `~/.pi/agent/prompts/`
- [x] 2.2 Add `xdg.configFile` entries in the same module linking the 5 OpenCode skill directories to `~/.config/opencode/skills/` and 5 command files to `~/.config/opencode/commands/`
- [x] 2.3 Use `lib.mkDefault` or similar guarding so users can override individual entries if needed
- [x] 2.4 Import `home-manager/openspec.nix` in `home-manager/home.nix`

## 3. Build and verify

- [x] 3.1 Run `make home-build` and confirm no evaluation errors
- [x] 3.2 Verify all 20 files exist in the Nix store at the correct paths
- [x] 3.3 Check that individual file links work alongside other existing OpenCode config files (AGENTS.md, config.json) and the AGENTS.md managed by the Pi module
