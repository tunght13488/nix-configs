# Proposal

## Why

The knowledge-assistant workspace needs Mermaid syntax validation inside pi-box. A dedicated template makes `mmdlint` available to that workspace without adding its dependencies to every sandbox's shared base image.

## What Changes

- Add a `knowledge-assistant` pi-box template that extends `pi-sandbox` and provides the `mmdlint` CLI using a pinned npm package version.
- Use the generic manifest defaults; the template adds no host grants.
- Document the new template and specify its behavior in the existing template catalog capability.
- Leave the shared base image, pi-box wrapper, and other templates unchanged.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `pi-box-templates`: require the `knowledge-assistant` template to provide Mermaid Markdown validation through `mmdlint`.

## Impact

- `home-manager/pi-box-templates/knowledge-assistant/`: new template source, deployed by the existing recursive Home Manager template deployment.
- `AGENTS.md`: add the template to the catalog and document its purpose.
- `openspec/specs/pi-box-templates/spec.md`: add the template behavior and validation scenario.
- No changes to the shared `pi-sandbox` image, grants, wrapper, or external knowledge-assistant workspace are in scope.
