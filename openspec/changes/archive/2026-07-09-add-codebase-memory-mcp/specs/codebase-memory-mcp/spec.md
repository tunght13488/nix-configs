## ADDED Requirements

### Requirement: Binary is available as a Nix package

The system SHALL provide the codebase-memory-mcp binary as a Nix package via `pkgs.codebase-memory-mcp`, fetching the pre-built static portable binary from the GitHub releases.

#### Scenario: Package builds successfully
- **WHEN** `nix build .#codebase-memory-mcp` is evaluated
- **THEN** the binary is present at `result/bin/codebase-memory-mcp` and reports its version when run with `--version`

#### Scenario: Binary is executable
- **WHEN** the package is installed into a user profile or home-manager environment
- **THEN** `codebase-memory-mcp --version` outputs a version string starting with `v0.9.`

### Requirement: Home-manager module installs the binary

The system SHALL provide a home-manager module at `modules/home-manager/codebase-memory-mcp.nix` that, when enabled, adds the binary to `home.packages`.

#### Scenario: Module disabled by default
- **WHEN** the module is imported but not enabled
- **THEN** `codebase-memory-mcp` is NOT present in the user's PATH

#### Scenario: Module enabled installs binary
- **WHEN** `codebase-memory-mcp.enable = true`
- **THEN** `codebase-memory-mcp` is available in the user's PATH

### Requirement: Package bundles the pi skill file

The Nix package SHALL include the pi skill file at `$out/share/pi/skills/codebase-memory/SKILL.md`, installable from a source file alongside the package definition.

#### Scenario: Skill file in package output
- **WHEN** `nix build .#codebase-memory-mcp` is evaluated
- **THEN** the file `result/share/pi/skills/codebase-memory/SKILL.md` exists and contains instructions for using the CLI codebase-memory tools

### Requirement: Pi skill is symlinked from the package

The home-manager module SHALL symlink the pi skill from the package output to `~/.pi/agent/skills/codebase-memory/SKILL.md` when enabled, following the same pattern as `herdrAgentFiles` and `openspecAgentFiles`.

#### Scenario: Symlink exists when module enabled
- **WHEN** `codebase-memory-mcp.enable = true` and home-manager is activated
- **THEN** `~/.pi/agent/skills/codebase-memory/SKILL.md` is a symlink to the Nix store path `$out/share/pi/skills/codebase-memory/SKILL.md`

### Requirement: Pi skill teaches code discovery protocol

The pi skill SHALL teach the agent the same code discovery protocol as the upstream `install` command provides to Claude Code: preference for graph tools over grep, a decision matrix mapping question types to tools, exploration and tracing workflows, and tool-specific gotchas.

#### Scenario: Skill file exists when module enabled
- **WHEN** `codebase-memory-mcp.enable = true` and home-manager is activated
- **THEN** the file `~/.pi/agent/skills/codebase-memory/SKILL.md` exists and contains instructions for using the CLI codebase-memory tools

#### Scenario: Skill teaches exploration workflow
- **WHEN** the agent reads the skill file
- **THEN** the skill instructs the agent to run `get_architecture` first when entering an unfamiliar project, `get_graph_schema` to understand node types, `search_graph` to find symbols, and `get_code_snippet` to read discovered source

#### Scenario: Skill teaches code discovery priority
- **WHEN** the agent reads the skill file
- **THEN** the skill states that graph tools (search_graph, trace_path, query_graph) SHALL be preferred over grep/glob for code structure discovery, with grep/glob reserved for string literals, config values, and non-code files

#### Scenario: Skill covers all 14 CLI tools
- **WHEN** the agent needs to perform any code discovery task
- **THEN** the skill documents the CLI invocation for each relevant tool: `index_repository`, `get_architecture`, `get_graph_schema`, `search_graph`, `trace_path`, `detect_changes`, `get_code_snippet`, `query_graph`, `search_code`, `list_projects`, `index_status`, `manage_adr`, `ingest_traces`, `semantic_query`

### Requirement: Module can be toggled independently

The system SHALL allow enabling or disabling codebase-memory-mcp without affecting other AI tooling configurations (claude-code, opencode, herdr, openspec).

#### Scenario: Module disabled does not affect other config
- **WHEN** `codebase-memory-mcp.enable = false`
- **THEN** no codebase-memory-mcp files, packages, or skill files are present, and all other home-manager configurations remain unchanged
