# Design

## Context

`programs.ngrok` (module: `modules/home-manager/ngrok.nix`) defaults its
`package` option to `pkgs.ngrok` via `lib.mkPackageOption pkgs "ngrok"`.
The single consumer (`home-manager/ngrok.nix`) does not override it, so
the agent currently comes from nixos-26.05 stable (3.31.0). The flake
already applies `inputs.self.overlays.unstable-packages` in
`home-manager/home.nix`, making `pkgs.unstable` available. See
proposal.md — Why for motivation.

## Goals / Non-Goals

**Goals:**
- ngrok agent tracks nixos-unstable (currently 3.39.10).
- Follow the repo's existing unstable opt-in pattern.
- Keep build-time config validation working against the new binary.

**Non-Goals:**
- No changes to endpoints, `settings`, or authtoken handling.
- No change to the module's default `package` for other (hypothetical)
  consumers.
- No flake input updates (`nixpkgs-unstable` stays at its current pin;
  upgrading it further is a separate `make update` decision).

## Decisions

### Decision: Set `package` at the consumer, not in the module default

Add `package = pkgs.unstable.ngrok;` inside the `programs.ngrok` block in
`home-manager/ngrok.nix`.

Rationale: every unstable opt-in in this repo happens at the consumer
(`programs.opencode.package = pkgs.unstable.opencode` in
`home-manager/ai.nix`, `package = pkgs.unstable._1password-cli` in
`nixos/configuration.nix`, `unstable.git-town` in `home-manager/git.nix`).
The module stays neutral — stable by default — matching how upstream
home-manager modules behave.

Alternative considered: change the module default to
`pkgs.unstable.ngrok`. Rejected: it couples the reusable module to the
unstable overlay, and the repo has exactly one pattern for this already.

### Decision: No other config changes

The module derives both the wrapper binary and the `staticConfig`
validation step from `cfg.package`:

- wrapper: `exec ${lib.getExe cfg.package} ...`
- validation: `${lib.getExe cfg.package} config check --config ...`

Overriding `cfg.package` therefore re-targets both automatically; no
module edits are needed.

## Risks / Trade-offs

- [Newer agent rejects or deprecates config keys used in
  `home-manager/ngrok.nix`] → The `staticConfig` build runs
  `ngrok config check` with the new binary, so this fails the build
  (`make home-build`) before activation, not the running tunnel.
- [Unstable package is temporarily broken on nixos-unstable] → The pin
  only moves on `nix flake update`; the current pin is known-good.
  Rollback is reverting the one-line override.
- [Version drift between agent and ngrok service expectations] → Low;
  ngrok's free-tier agent protocol is server-negotiated. If a tunnel
  misbehaves after the bump, `ngrok` logs and the web inspector at
  `0.0.0.0:4040` are the first places to check.

## Migration Plan

Apply via the normal home-manager flow: `make home-build` to verify,
then the user runs `make home`. No state migration; rollback is a
one-line revert plus rebuild.
