# Proposal

## Why

The PHP82 and PHP83 templates set `network.connect_port: [3306]` to reach host MySQL. On Linux, Nono treats this as a TCP port allowlist, so with the default profile it also denies direct HTTPS on port 443; model requests fail with `EACCES`. The user confirmed that removing the setting restores model access, but new projects scaffolded from either template would still inherit it.

## What Changes

- Remove the `network.connect_port` restriction from the PHP82 and PHP83 templates while retaining `DB_HOST=127.0.0.1`; the shared pi-box base already allows outbound networking.
- Add a regression check that both templates omit `network.connect_port` and retain the database host setting.
- Update the PHP template requirements to cover outbound HTTPS access under the default-allow base alongside host MySQL configuration.

This does not modify the shared base, the per-run overlay, proxy behavior, or existing project-local profiles.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `pi-box-templates`: PHP templates must retain the shared default outbound network policy while keeping their host database configuration.

## Impact

- `home-manager/pi-box-templates/php82/pi-box.profile.json`
- `home-manager/pi-box-templates/php83/pi-box.profile.json`
- `home-manager/pi-box-check.sh`
- `openspec/specs/pi-box-templates/spec.md`

Existing `pi-box.profile.json` files are copied into projects and ignored by Git, so this change affects future scaffolds; an existing project profile must be updated separately.
