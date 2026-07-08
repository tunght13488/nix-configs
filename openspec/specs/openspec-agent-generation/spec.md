## Purpose

Generate pi agent prompt templates, agent skill files, and opencode slash commands and skills from the OpenSpec source repository at a pinned version, producing a derivation output compatible with home-manager consumption.

## Requirements

### Requirement: Derivation fetches OpenSpec source at pinned version
The Nix derivation SHALL fetch the OpenSpec repository source from `github.com/Fission-AI/OpenSpec` at a pinned git tag or commit revision.

#### Scenario: Fetch succeeds for valid tag
- **WHEN** the derivation is built with a valid `rev` (e.g., `v1.5.0`)
- **THEN** the source tree is available in the build sandbox at the expected path

#### Scenario: Fetch fails for invalid tag
- **WHEN** the derivation is built with a non-existent `rev`
- **THEN** the Nix build fails with a fetch error

### Requirement: Build script generates pi prompt templates
The derivation SHALL produce pi slash command files at `.pi/prompts/opsx-<id>.md` for all core profile workflows, formatted with YAML frontmatter containing a `description` field.

#### Scenario: All pi prompts generated
- **WHEN** the build completes
- **THEN** `.pi/prompts/` contains exactly 11 files: `opsx-apply.md`, `opsx-archive.md`, `opsx-bulk-archive.md`, `opsx-continue.md`, `opsx-explore.md`, `opsx-ff.md`, `opsx-new.md`, `opsx-onboard.md`, `opsx-propose.md`, `opsx-sync.md`, `opsx-verify.md`

#### Scenario: Pi prompt format
- **WHEN** any generated pi prompt file is read
- **THEN** it begins with `---\ndescription: ...\n---\n` YAML frontmatter
- **AND** the body contains `/opsx-` command references (hyphen form, not `/opsx:` colon form)
- **AND** the body contains `**Provided arguments**: $@` for template argument passthrough

### Requirement: Build script generates pi agent skills
The derivation SHALL produce pi agent skill files at `.pi/skills/openspec-<id>/SKILL.md` for all core profile workflows, formatted with Agent Skills YAML frontmatter including `name`, `description`, `allowed-tools`, `license`, `compatibility`, and `metadata.generatedBy` fields.

#### Scenario: All pi skills generated
- **WHEN** the build completes
- **THEN** `.pi/skills/` contains exactly 11 subdirectories: `openspec-apply-change`, `openspec-archive-change`, `openspec-bulk-archive-change`, `openspec-continue-change`, `openspec-explore`, `openspec-ff-change`, `openspec-new-change`, `openspec-onboard`, `openspec-propose`, `openspec-sync-specs`, `openspec-verify-change`

#### Scenario: Pi skill YAML frontmatter
- **WHEN** any generated pi skill file is read
- **THEN** it contains frontmatter fields: `name`, `description`, `allowed-tools: Bash(openspec:*)`, `license: MIT`, `metadata.generatedBy`
- **AND** the instructions body uses `/opsx-` hyphen-form command references

### Requirement: Build script generates opencode slash commands
The derivation SHALL produce opencode slash command files at `.opencode/commands/opsx-<id>.md` for all core profile workflows, formatted with `description` frontmatter.

#### Scenario: All opencode commands generated
- **WHEN** the build completes
- **THEN** `.opencode/commands/` contains exactly 11 files matching the same workflow IDs as pi prompts

#### Scenario: Opencode command format
- **WHEN** any generated opencode command file is read
- **THEN** it begins with `---\ndescription: ...\n---\n` frontmatter
- **AND** the body contains `/opsx-` command references

### Requirement: Build script generates opencode agent skills
The derivation SHALL produce opencode agent skill files at `.opencode/skills/openspec-<id>/SKILL.md` for all core profile workflows.

#### Scenario: All opencode skills generated
- **WHEN** the build completes
- **THEN** `.opencode/skills/` contains exactly 11 subdirectories matching the same names as pi skills

### Requirement: Derivation output matches home-manager consumer expectations
The derivation output directory structure SHALL be compatible with `home-manager/openspec.nix`, which symlinks individual files from `${openspecAgentFiles}/.pi/...` and `${openspecAgentFiles}/.opencode/...`.

#### Scenario: home-manager symlinks resolve correctly
- **WHEN** `home-manager/openspec.nix` references `${openspecAgentFiles}/.pi/prompts/opsx-explore.md`
- **THEN** the file exists at that path within the derivation output

#### Scenario: No missing files after update
- **WHEN** the derivation version is updated and `make home-build` is run
- **THEN** all 34 file paths referenced in `home-manager/openspec.nix` still resolve in the derivation output

### Requirement: Version update is a single-line change
Changing the pinned OpenSpec version SHALL require only updating the `rev` and `hash` fields in the derivation, with no manual file generation or copying.

#### Scenario: Update from v1.5.0 to v1.6.0
- **WHEN** `rev` is changed to `v1.6.0` and `hash` is updated to match
- **THEN** `make home-build` succeeds and produces output from the updated source
