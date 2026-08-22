## Why

The main `nixpkgs` input is pinned to an August 2025 commit on `nixos-25.11` — a year of drift. Updating to `nixos-26.05` is blocked by one hard incompatibility: `mysql80` was dropped from nixpkgs unstable in April 2026 (PR #507865) and the removal was inherited by the 26.05 release branch, while upstream MySQL 8.0 reached EOL on April 30, 2026 (final release 8.0.46). The local LAMP dev stack still requires MySQL 8.0, so the platform update and the MySQL pin must move together.

## What Changes

- Bump the main `nixpkgs` input from `nixos-25.11` to `nixos-26.05`, and update `flake.lock` for it.
- Bump `home-manager` from `release-25.11` to `release-26.05` (branch must match nixpkgs release).
- Bump `nixvim` from `nixos-25.11` to `nixos-26.05` (branch must match nixpkgs release).
- Add a new flake input `nixpkgs-2511` pinned to the `nixos-25.11` branch (which still ships `mysql80` 8.0.46) and expose `mysql80` from it via the existing overlay pattern (same shape as `unstable-packages`).
- Keep `nixos/mysql.nix` pointing at `pkgs.mysql80` — no change to the module usage.
- Keep `phps`, `agenix`, `nix-index-database`, `herdr`, and `nixpkgs-unstable` inputs as-is; refresh their lock entries to match the new 26.05 base where they follow nixpkgs.

Non-goals:

- No migration to `mysql84` or any other database — the datadir stays on 8.0; a future migration is a separate change.
- No switch of the main input to unstable (rejected: unstable dropped mysql80 first; release branches keep hm/nixvim branch parity).
- No changes to the unstable overlay's app pins (postman, openspec, editors, 1Password).
- No cleanup of the dead `php81` override in the `modifications` overlay (phps overlay overwrites it; harmless, separate concern).

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

(none)

Pure infrastructure/tooling change: system behavior is unchanged (same services, same MySQL 8.0, same packages modulo version bumps within 26.05). `skip_specs: true` is set in `.openspec.yaml`.

## Impact

- **`flake.nix`**: input URLs (nixpkgs, home-manager, nixvim), new `nixpkgs-2511` input, overlay wiring for the mysql80 side-pin.
- **`overlays/default.nix`**: new overlay (or extension of an existing one) exposing `mysql80` from the pinned 25.11 input.
- **`nixos/configuration.nix`** / **`flake.nix` devShells**: no functional change expected, but both must still evaluate against 26.05.
- **Risk points** (verified during exploration):
  - `mysql80` builds from cache.nixos.org for 25.11 — no long compile expected.
  - The 26.05 `services.mysql` module (post PR #508374) is package-agnostic; a pinned non-branch package still evaluates (module only dropped pre-8.0 `notify` fallback logic).
  - `docker_29`, `jdk8`, `maven363` override, fossar `phps` overlay all still exist on 26.05.
  - `prev.php81` in the `modifications` overlay refers to an attr that no longer exists in 26.05 nixpkgs — safe only because the phps overlay replaces it before evaluation forces it; must not be disturbed.
  - Version drift on the platform layer: nodejs 22→24 (fc-omx shell pins `nodejs_22` explicitly and is unaffected), go 1.24→1.26, docker 27→29 (already aliased).
- **Verification**: `make home-build` and `make os-build` must pass; `nix flake show --no-write-lock-file` for lock validation. Applying (`make os`) is done by the user, not the agent.
