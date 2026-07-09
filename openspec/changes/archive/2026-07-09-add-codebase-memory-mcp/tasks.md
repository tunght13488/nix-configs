## 1. Nix package

- [x] 1.1 Create `pkgs/codebase-memory-mcp/skill.md` — pi skill file with decision matrix, workflows, gotchas, all 14 CLI tool commands
- [x] 1.2 Create `pkgs/codebase-memory-mcp/default.nix` — `fetchurl` the portable binary from GitHub releases v0.9.0, extract tar.gz, install binary to `$out/bin/` and skill file to `$out/share/pi/skills/codebase-memory/SKILL.md`
- [x] 1.3 Register package in `pkgs/default.nix` — add `codebase-memory-mcp = pkgs.callPackage ./codebase-memory-mcp { };`
- [x] 1.4 Verify with `nix build .#codebase-memory-mcp` — check `result/bin/codebase-memory-mcp --version` and `result/share/pi/skills/codebase-memory/SKILL.md` exists

## 2. Home-manager module

- [x] 2.1 Create `modules/home-manager/codebase-memory-mcp.nix` with `mkEnableOption`, `home.packages`, and `home.file` symlink to package skill file
- [x] 2.2 Register module in `modules/home-manager/default.nix` — add `codebase-memory-mcp = import ./codebase-memory-mcp.nix;`
- [x] 2.3 Import module in `home-manager/home.nix` — add `inputs.self.homeManagerModules.codebase-memory-mcp` to imports
- [x] 2.4 Enable the module — add `programs.codebase-memory-mcp.enable = true;` in appropriate location (e.g., `home-manager/ai.nix` or inline in `home.nix`)
- [x] 2.5 Verify with `make home-build`

## 3. Pi skill content

- [x] 3.1 Ensure skill teaches code discovery priority: graph tools (search_graph, trace_path, query_graph) over grep/glob for code structure
- [x] 3.2 Ensure skill includes decision matrix mapping question types to tools (matching upstream Claude Code skill)
- [x] 3.3 Ensure skill covers exploration workflow: get_architecture → get_graph_schema → search_graph → get_code_snippet
- [x] 3.4 Ensure skill covers tracing workflow: search_graph → trace_path → detect_changes
- [x] 3.5 Ensure skill covers quality analysis: dead code detection, fan-out/fan-in
- [x] 3.6 Ensure skill documents gotchas: 200-row Cypher cap, trace needs exact names, pagination
- [x] 3.7 Ensure all CLI commands use correct JSON argument syntax with examples
- [x] 3.8 Verify symlink `~/.pi/agent/skills/codebase-memory/SKILL.md` points into Nix store after `make home-build`

## 4. Validation

- [x] 4.1 Run `make home-build` — home-manager evaluation succeeds
- [x] 4.2 Run `nix flake check --no-write-lock-file` — flake checks pass
- [x] 4.3 Run `nix fmt` — formatting is clean
- [x] 4.4 Git add all new files and verify they are tracked
