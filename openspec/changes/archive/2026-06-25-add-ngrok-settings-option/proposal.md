## Why

The ngrok home-manager module hardcodes the static config to only `version` and
`endpoints`. There is no way for a user to set other top-level ngrok keys (e.g.
`web_addr`, `region`, `log_level`). Concretely, the VMware host needs to reach
ngrok's local web inspector at `http://<vm-ip>:4040`, which requires
`web_addr: 0.0.0.0:4040` — currently impossible without editing the module.

## What Changes

- Add a freeform `programs.ngrok.settings` option (`attrsOf yaml.type`) to
  `modules/home-manager/ngrok.nix` for top-level ngrok config keys.
- Merge `cfg.settings` into the static config render **before** the managed
  `version`/`endpoints` keys so managed keys always win on conflict.
- Add an **eval-time assertion** that fails loudly if `settings` contains
  `version` or `endpoints` (no silent override).
- Set `programs.ngrok.settings.web_addr = "0.0.0.0:4040";` in
  `home-manager/ngrok.nix` to expose the inspector on all interfaces.
- Authtoken fragment (`ngrok-authtoken.yml`) is **unchanged**; `web_addr` lives
  only in the static `ngrok.yml`.

## Capabilities

### New Capabilities
- `ngrok-tunnel-config`: The home-manager ngrok module provides a typed,
  freeform `settings` option for top-level ngrok configuration keys, with
  guarded merge semantics against managed keys.

### Modified Capabilities
<!-- No existing capabilities have requirement changes. -->
*None*

## Impact

- **`modules/home-manager/ngrok.nix`**: New `settings` option, render-order
  change in `staticConfig`, new `assertions` entry.
- **`home-manager/ngrok.nix`**: One new line setting `web_addr`.
- **No breaking changes**: `settings` defaults to `{}`, so existing consumers
  evaluate identically.
- **Security note**: `web_addr: 0.0.0.0:4040` exposes the ngrok inspector
  (request/replay UI) on all interfaces. Acceptable here because the VM's
  `4040` port is whitelisted on a trusted host-only/vmnet network.
