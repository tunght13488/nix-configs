## MODIFIED Requirements

### Requirement: Derivation fetches OpenSpec source at pinned version
The Nix derivation SHALL fetch the OpenSpec repository source from `github.com/Fission-AI/OpenSpec` at a pinned git tag or commit revision.

#### Scenario: Fetch succeeds for valid tag
- **WHEN** the derivation is built with a valid `rev` (e.g., `v1.13.2`)
- **THEN** the source tree is available in the build sandbox at the expected path

#### Scenario: Fetch fails for invalid tag
- **WHEN** the derivation is built with a non-existent `rev`
- **THEN** the Nix build fails with a fetch error

### Requirement: Derivation output matches home-manager consumer expectations
The derivation output directory structure SHALL be compatible with `home-manager/openspec.nix`, which symlinks individual files from `${openspecAgentFiles}/.pi/...` and `${openspecAgentFiles}/.opencode/...`.

#### Scenario: home-manager symlinks resolve correctly
- **WHEN** `home-manager/openspec.nix` references `${openspecAgentFiles}/.pi/prompts/opsx-update.md`
- **THEN** the file exists at that path within the derivation output

#### Scenario: No missing files after update
- **WHEN** the derivation version is updated to v1.13.2 and `make home-build` is run
- **THEN** all file paths referenced in `home-manager/openspec.nix` still resolve in the derivation output

### Requirement: Version update is a single-line change
Changing the pinned OpenSpec version SHALL require only updating the `rev` and `hash` fields in the derivation, with no manual file generation or copying.

#### Scenario: Update from v1.5.0 to v1.8.0
- **WHEN** `rev` is changed to `v1.8.0` and `hash` is updated to match
- **THEN** `make home-build` succeeds and produces output from the updated source

#### Scenario: Update from v1.8.0 to v1.13.2
- **WHEN** `rev` is changed to `v1.13.2` and `hash` is updated to match
- **THEN** `make home-build` succeeds and produces output from the updated source
