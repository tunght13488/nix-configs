# Spec Delta

## ADDED Requirements

### Requirement: knowledge-assistant template provides Mermaid linting
The `knowledge-assistant` template SHALL provide the `mmdlint` CLI for validating Mermaid blocks in Markdown files in the project workspace, without requiring a separate project-level install.

#### Scenario: Validate Mermaid Markdown in a scaffolded workspace
- **WHEN** a project is scaffolded with `pi-box init knowledge-assistant` and `mmdlint docs/PROJECT.md` runs inside its sandbox
- **THEN** the CLI is available and validates the Mermaid blocks in that workspace file
