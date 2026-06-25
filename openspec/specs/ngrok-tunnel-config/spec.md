## Purpose

Provide a typed, freeform `settings` option on `programs.ngrok` for setting
arbitrary top-level ngrok configuration keys, with guarded merge semantics
that prevent clobbering the module-managed `version` and `endpoints` keys.

## Requirements

### Requirement: Freeform settings option for top-level ngrok keys
The `programs.ngrok` home-manager module SHALL expose a `settings` option of
type `attrsOf yaml.type` (freeform YAML) that accepts arbitrary top-level
ngrok configuration keys. It SHALL default to `{}` so existing consumers
evaluate identically when the option is unset.

#### Scenario: Default value is empty
- **WHEN** `programs.ngrok.settings` is not set by the consumer
- **THEN** the module evaluates with `settings = {}` and the rendered static
  config contains only the managed `version` (and `endpoints` when defined)

#### Scenario: User sets a top-level key
- **WHEN** the consumer sets `programs.ngrok.settings.web_addr = "0.0.0.0:4040"`
- **THEN** the rendered static `ngrok.yml` contains `web_addr: 0.0.0.0:4040`
  as a top-level key

### Requirement: Managed keys are protected by eval-time assertion
The module SHALL fail evaluation with a clear error message if
`programs.ngrok.settings` contains the keys `version` or `endpoints`. These
keys are managed by the module itself and MUST NOT be clobbered silently.

#### Scenario: Setting version is rejected
- **WHEN** the consumer sets `programs.ngrok.settings.version`
- **THEN** Nix evaluation fails with a message naming `version` as a managed
  key that cannot be set via `settings`

#### Scenario: Setting endpoints is rejected
- **WHEN** the consumer sets `programs.ngrok.settings.endpoints`
- **THEN** Nix evaluation fails with a message naming `endpoints` as a
  managed key that cannot be set via `settings`

#### Scenario: Other top-level keys are accepted
- **WHEN** the consumer sets `programs.ngrok.settings.web_addr`,
  `programs.ngrok.settings.region`, or `programs.ngrok.settings.log_level`
- **THEN** evaluation succeeds and the keys appear in the rendered static
  config

### Requirement: Managed keys win on merge conflict
When rendering the static config, the module SHALL merge `cfg.settings`
**before** the managed `version` and `endpoints` keys using Nix attrset
update semantics (`//`), so that managed keys always take precedence even
if the assertion is bypassed.

#### Scenario: Merge order guarantees managed version
- **WHEN** the assertion were bypassed and `settings` contained `version`
- **THEN** the rendered config would still contain the module-managed
  `version: "3"` value

### Requirement: Authtoken fragment is unaffected
The `ngrok-authtoken.yml` fragment written by the activation script SHALL NOT
be modified by this change. User-supplied `settings` SHALL only affect the
static `ngrok.yml` produced by `staticConfig`.

#### Scenario: Settings do not leak into authtoken fragment
- **WHEN** the consumer sets `programs.ngrok.settings.web_addr`
- **THEN** the authtoken fragment contains only `version` and
  `agent.authtoken`, with no `web_addr` key
