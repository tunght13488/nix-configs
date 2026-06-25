## Context

The ngrok home-manager module (`modules/home-manager/ngrok.nix`) builds two
config files:

1. **Static `ngrok.yml`** — rendered from `staticConfig`, symlinked by
   home-manager into `~/.config/ngrok/ngrok.yml`. Currently contains only
   `version: "3"` and (optionally) `endpoints`.
2. **Authtoken fragment `ngrok-authtoken.yml`** — written at activation time
   from an agenix secret, contains `version: "3"` and `agent.authtoken`.

The `ngrok` wrapper invokes the binary with `--config <authtoken>
--config <static>`, and ngrok merges them. The static config is the right
home for any non-secret top-level ngrok key.

Today `staticConfig` (line 13-20) renders a fixed shape:
`{ version = "3"; } // optionalAttrs (endpoints != {}) { endpoints = ...; }`.
There is no escape hatch for other top-level keys (`web_addr`, `region`,
`log_level`, `inspect_db_size`, …).

The `endpoints` submodule already uses `freeformType = yaml.type` (line 52,
line 68 for the nested `upstream`), establishing the freeform-YAML pattern
in this module.

## Goals / Non-Goals

**Goals:**
- Let users set arbitrary top-level ngrok keys via a typed freeform option.
- Preserve the managed/managed-key invariant: `version` and `endpoints`
  are owned by the module and cannot be clobbered by user input.
- Fail loudly (eval-time assertion) on attempted clobber — no silent
  override.
- Expose the web inspector on `0.0.0.0:4040` so the VMware host can reach
  it at `http://<vm-ip>:4040`.

**Non-Goals:**
- Typed per-key options for every ngrok top-level key (would be churn).
- Modifying the authtoken fragment or activation script.
- Changing the wrapper's `--config` ordering.
- Adding firewall rules for `4040` (already whitelisted in the VM).

## Decisions

### 1. Freeform `settings` option, not per-key typed options

- *Rationale*: ngrok's top-level schema is open and stable; pinning a typed
  `mkOption` per key would create ongoing churn for no safety benefit. The
  module already uses `freeformType = yaml.type` for the `endpoints`
  submodule, so this is the established house pattern.
- *Alternative considered*: A dedicated `programs.ngrok.webAddr` option.
  Rejected — one-off, and the next key (`region`, `log_level`) would force
  another round of edits. The user explicitly chose freeform.

### 2. Merge order: `settings` first, managed keys last

Render shape:
```nix
{ version = "3"; }
// cfg.settings
// lib.optionalAttrs (cfg.endpoints != { }) { endpoints = lib.attrValues cfg.endpoints; }
```
Nix `//` is left-biased, so later attrsets win. Placing the managed
`version`/`endpoints` *after* `cfg.settings` means even if the assertion
were bypassed, the managed values still take precedence — defense in depth.

- *Alternative considered*: Placing `settings` last and relying solely on
  the assertion. Rejected — silent-on-bypass is a worse failure mode than
  the loud assertion + managed-wins belt-and-braces approach the user
  asked for.

### 3. Loud eval-time assertion for managed-key clobber

```nix
assertions = [
  {
    assertion = !(cfg.settings ? version || cfg.settings ? endpoints);
    message = "programs.ngrok.settings: 'version' and 'endpoints' are managed "
      + "by the module and cannot be set here.";
  }
];
```
This produces a clear Nix evaluation error naming the offending keys,
matching the user's "do not fail silently" directive.

- *Alternative considered*: Silent override via plain `//` with no
  assertion. Explicitly rejected by the user.

### 4. `web_addr` lives in the static file only

`web_addr` is not a secret and does not need to be in the authtoken
fragment. The wrapper passes both files to ngrok; ngrok merges them. One
file is sufficient. Keeping the authtoken fragment unchanged preserves
its single responsibility (inject the secret).

## Risks / Trade-offs

- [Silent clobber if assertion bypassed via `mkForce`] → Mitigated by
  merge order: managed keys are placed *after* `cfg.settings`, so even
  `mkForce` on `settings.version` would still lose to the literal
  `version = "3"` unless the user also force-overrides the managed key.
  This is acceptable — anyone reaching for `mkForce` is opting out of
  the guardrails intentionally.
- [Exposure of inspector on `0.0.0.0:4040`] → The inspector shows live
  request bodies and supports replay. Acceptable here because the VM's
  `4040` is on a trusted host-only/vmnet network and is already
  whitelisted. Not a general recommendation.
- [Freeform YAML loses per-key type checking] → Accepted trade-off;
  ngrok's own `config check` (already run in `staticConfig`'s
  `runCommand`, line 28) catches malformed keys at build time.
