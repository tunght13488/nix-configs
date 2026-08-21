# Design: update-to-26-05-pin-mysql80

## Context

See proposal.md — Why. Current state: main `nixpkgs` on `nixos-25.11` (Aug 2025 rev), `services.mysql` uses `pkgs.mysql80`, which no longer exists on `nixos-26.05`. The config already has an established pattern for pulling packages from a second nixpkgs: the `unstable-packages` overlay imports `inputs.nixpkgs-unstable` and exposes it as `pkgs.unstable`.

## Goals / Non-Goals

Goals:

- Main platform on 26.05 with hm/nixvim branches matching.
- MySQL 8.0 continues to work with zero datadir change and cache-served binaries.

Non-Goals (design-level):

- No per-package imports from the 25.11 input beyond `mysql80` (e.g. no `libmysqlclient` side-pins) — 26.05's `libmysqlclient` aliases to mariadb-connector-c and is fine for clients like `mycli`.
- No restructuring of overlays beyond the minimum needed for the side-pin.

## Decisions

### D1: Side-pin via a dedicated flake input, not `nixpkgs-unstable` and not `follows`

Add `nixpkgs-mysql80.url = "github:NixOS/nixpkgs/nixos-25.11"` and expose only `mysql80` from it.

- Alternative rejected: pull mysql80 from the *existing* `nixos-25.11` main input and only bump the other inputs — impossible, the main input is the thing being bumped.
- Alternative rejected: `follows` from some other input (agenix/nix-index-database follow main nixpkgs and will move to 26.05 with it; none of them stay on 25.11 by design).
- Alternative rejected: keep main on 25.11 and only bump hm/nixvim — breaks the branch-parity requirement between home-manager and nixpkgs.

The input follows nothing; it is pinned independently in `flake.lock`.

### D2: Expose as a top-level attr in a new overlay entry, not via `pkgs.unstable`-style nested set

Add to `overlays/default.nix` a small overlay (e.g. `mysql80-packages`) setting `mysql80 = (import inputs.nixpkgs-mysql80 { inherit (final) system; }).mysql80;`, and append it to the overlay lists in `nixosConfigurations` and (if needed for devShells/home) the other import sites.

- Rationale: `nixos/mysql.nix` keeps referencing plain `pkgs.mysql80`; no churn in the module usage.
- Alternative rejected: `pkgs.mysql80-pinned.mysql80` nesting — more explicit but forces edits in `mysql.nix` for no real gain; the plain name is what every other consumer (services.mysql docs, muscle memory) expects.
- Note: nixpkgs 25.11's `mysql80` builds against its own 25.11 dependency closure, so no `config.allowUnfree` or overlay composition is needed for the import — plain `import` is sufficient. (`allowUnfree` is irrelevant for mysql80.)

### D3: Where the overlay is applied

The overlay must be applied anywhere `pkgs.mysql80` is referenced:

- `nixosConfigurations.nixos-vmware` specialArgs overlay list (system layer — the only consumer today, via `nixos/mysql.nix`).
- Not applied in `homeConfigurations` or `devShells` unless something there references `mysql80` — currently nothing does (`mycli` uses stable's own package).

### D4: Branch bumps for hm/nixvim

- `home-manager`: `github:nix-community/home-manager/release-26.05`, keep `inputs.nixpkgs.follows = "nixpkgs"`.
- `nixvim`: `github:nix-community/nixvim/nixos-26.05`, keep default nixpkgs follow behavior (nixvim follows its own nixpkgs input — verify after bump that no option renames break the eval; `make home-build` will catch it).
- `phps` (fossar/nix-phps) stays on master with `follows nixpkgs` — it targets the nixpkgs it's given; 26.05's php82/83/84 attrs exist, php81 comes from fossar's own definitions (unaffected by the branch bump).

### D5: Version drift acceptance

Platform-layer drift within 26.05 is accepted: nodejs 22→24 for the default `nodejs` attr (fc-omx devShell pins `nodejs_22` explicitly), go 1.24→1.26, GNOME/kernel refresh. These are the normal consequences of a release bump, not something to counter-pin. The unstable overlay keeps its existing per-package pins unchanged.

## Risks / Trade-offs

- [25.11 branch freeze: mysql80 stops receiving fixes once the branch goes EOL (~Nov 2026)] → Accepted: 8.0.46 is upstream-final (EOL Apr 2026) regardless; localhost-only dev VM, same risk class as php81/php82. The lockfile freeze makes this static either way.
- [26.05 hm/nixvim option renames break eval] → `make home-build` / `make os-build` gate the change; failures are eval-time and fixable in the same commit.
- [`prev.php81` in `modifications` overlay references an attr removed from 26.05] → Works only because the `phps` overlay replaces `php81` before anything forces it (laziness) AND `modifications` runs before `phps`. Do not reorder the overlay list; leave the php81 override block alone in this change.
- [mysql80 from 25.11 might collide with 26.05 libraries at runtime] → Not a real concern: the derivation carries its own 25.11 closure; nothing on the system links against it except via its own `lib/mysql` paths.
- [Rollback] → Generational rollback is safe: the datadir never changes schema (8.0→8.0), so switching back to a 25.11-based generation restores a compatible mysql80.

## Migration Plan

1. Edit inputs (nixpkgs, home-manager, nixvim → 26.05 branches; add nixpkgs-mysql80).
2. Wire the side-pin overlay and append to the system overlay list.
3. `nix flake update` (or targeted `nix flake lock --update-input` for the changed inputs) — expect a large diff on the nixpkgs node.
4. `make os-build` then `make home-build`; fix any eval fallout.
5. User runs `make os` / `make home` to apply (agent never runs switch commands).
6. Post-switch smoke test: `systemctl status mysql`, `mysql -e 'SELECT VERSION();'` shows 8.0.x, php*.local sites respond.

Rollback: `nixos-rebuild --rollback`-equivalent via `nh` — generation switch back to the previous 25.11 config; datadir untouched.

## Open Questions

None — all questions raised during exploration were resolved (mysql80 availability per branch, module compatibility post-#508374, overlay ordering semantics, cache availability for 25.11 artifacts).
