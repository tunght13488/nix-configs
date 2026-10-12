# Tasks

## 1. Remove codebase-memory-mcp

- [ ] 1.1 Remove `programs.codebase-memory-mcp.enable = true;` from `home-manager/ai.nix` and the `inputs.self.homeManagerModules.codebase-memory-mcp` import from `home-manager/home.nix`; verify `rg -n "codebase-memory" home-manager/` reports no hits
- [ ] 1.2 Delete `modules/home-manager/codebase-memory-mcp.nix` and remove its export line from `modules/home-manager/default.nix`; verify `rg -n "codebase-memory" modules/` reports no hits
- [ ] 1.3 Delete `pkgs/codebase-memory-mcp/` (both `default.nix` and `skill.md`) and remove the `codebase-memory-mcp` entry from `pkgs/default.nix`; verify `rg -n "codebase-memory" pkgs/` reports no hits

## 2. Remove OpenSpec global integration and CLI

- [ ] 2.1 Delete `home-manager/openspec.nix` and remove the `./openspec.nix` import from `home-manager/home.nix`; verify `rg -n "openspec" home-manager/home.nix` reports no hits
- [ ] 2.2 Remove `unstable.openspec` from `home.packages` in `home-manager/home.nix`; verify the package list evaluates (covered by build in 3.2) and contains no openspec entry
- [ ] 2.3 Remove the `openspec = prev'.openspec.overrideAttrs ...` block from the `unstable-packages` overlay in `overlays/default.nix`; verify `rg -n "openspec" overlays/` reports no hits
- [ ] 2.4 Remove the `openspecAgentFiles` attribute from the `additions` overlay in `overlays/default.nix` and delete `pkgs/openspec-agent-files.nix` and `pkgs/generate-agent-files.mjs`; verify `rg -n "openspecAgentFiles|openspec-agent-files|generate-agent-files" --type nix -g '*.nix' -g '*.mjs'` reports no hits outside `openspec/`
- [ ] 2.5 Remove the commented-out `# # OpenSpec` block from the global ignore list in `home-manager/git.nix`; verify `rg -n "opsx|openspec" home-manager/git.nix` reports no hits

## 3. Verify

- [ ] 3.1 Run `nixpkgs-fmt` on every edited `.nix` file and verify `git diff --check` is clean
- [ ] 3.2 Run `make home-build` and verify the configuration builds with no openspec or codebase-memory references in the output
- [ ] 3.3 Run `rg -n -i "openspec|codebase-memory" home-manager/ modules/ pkgs/ overlays/ nixos/ flake.nix` and verify remaining hits are only historical comments pointing at `openspec/changes/...` docs (`nixos/configuration.nix`, `home-manager/hyprland.nix`)
- [ ] 3.4 After the user runs `make home`, verify `~/.pi/agent/skills/openspec-*`, `~/.pi/agent/skills/codebase-memory`, `~/.pi/agent/prompts/opsx-*.md`, `~/.config/opencode/skills/openspec-*`, `~/.config/opencode/commands/opsx-*.md` are gone and `openspec`/`codebase-memory-mcp` are no longer in PATH
