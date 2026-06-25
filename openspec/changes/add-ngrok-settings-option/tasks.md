## 1. Module changes (`modules/home-manager/ngrok.nix`)

- [ ] 1.1 Add `programs.ngrok.settings` option: `types.attrsOf yaml.type`,
  `default = {}`, with a `description` noting that `version` and
  `endpoints` are managed and cannot be set here.
- [ ] 1.2 Update `staticConfig` render so `cfg.settings` is merged
  *before* the managed `version`/`endpoints` keys:
  `{ version = "3"; } // cfg.settings // optionalAttrs (endpoints != {}) { endpoints = ...; }`
- [ ] 1.3 Add an `assertions` entry that fails evaluation when
  `cfg.settings ? version || cfg.settings ? endpoints`, with a message
  naming the managed keys.

## 2. Consumer config (`home-manager/ngrok.nix`)

- [ ] 2.1 Set `programs.ngrok.settings.web_addr = "0.0.0.0:4040";` so the
  inspector is reachable from the VMware host.

## 3. Verification

- [ ] 3.1 Run `make home-build` to confirm the config evaluates and
  builds. Confirm the rendered `ngrok.yml` contains
  `web_addr: 0.0.0.0:4040` at the top level.
- [ ] 3.2 Sanity-check the assertion: temporarily set
  `programs.ngrok.settings.version = "2";` and confirm `make home-build`
  fails with the managed-key message. Revert.
- [ ] 3.3 Confirm the authtoken fragment is unchanged (still only
  `version` + `agent.authtoken`).
- [ ] 3.4 Run `make format` and `nix flake check --no-write-lock-file`.
