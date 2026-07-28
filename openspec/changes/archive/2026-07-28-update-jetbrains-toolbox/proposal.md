## Why

`jetbrains-toolbox` is pinned to the `nixos-25.11` stable channel, which freezes it at **3.1.0.62320** for the lifetime of the release branch. Upstream is at **3.6.2.85969** (2026-07-16, nixpkgs PR #542679), and the currently running Toolbox process is actively launching with `--update-failed` because it cannot self-update a binary installed into the read-only `/nix/store`. The drift is permanent under the current pinning and will recur with every upstream release.

## What Changes

- Switch the home-manager package entry for `jetbrains-toolbox` from the nixpkgs-25.11 `jetbrains-toolbox` attribute to `unstable.jetbrains-toolbox`, matching the existing `unstable.*` convention already used in `home-manager/home.nix` (e.g. `unstable.postman`, `unstable.zed-editor`, `unstable.uv`, `unstable.openspec`).
- Bump only the `nixpkgs-unstable` flake input (via `nix flake update --input nixpkgs-unstable`) so the pinned unstable ref moves forward enough to resolve `jetbrains-toolbox` to a current upstream build. The `nixos-25.11`, `home-manager`, `nixvim`, `agenix`, and other release-branch inputs stay untouched to preserve repo-wide release-branch stability.
- No change to JetBrains IDE management: IDEs remain Toolbox-managed under `~/.local/share/JetBrains/Toolbox/apps/` and are out of scope. The launcher's own self-update behavior is also out of scope — it continues to be nix-managed and will still emit `--update-failed` if it attempts in-place self-update; this proposal accepts that tradeoff.

## Capabilities

### New Capabilities
- `jetbrains-toolbox`: Sourcing and version-tracking of the JetBrains Toolbox launcher via the nixpkgs-unstable flake input (mirrors the pinning contract used for `herdr-terminal-multiplexer`).

### Modified Capabilities
<!-- None. No existing capability's requirements change; `jetbrains-toolbox` has no prior spec. -->

## Impact

- **Code**: `home-manager/home.nix` — one line in `home.packages` (`jetbrains-toolbox` → `unstable.jetbrains-toolbox`).
- **Dependencies**: `flake.lock` — `nixpkgs-unstable` node revision (targeted bump only). No other inputs change.
- **Systems**: The home-manager build (`make home-build`) is the verification path; no NixOS system change, no new services, no secrets.
- **Runtime**: After apply, `which jetbrains-toolbox` resolves to a `*-jetbrains-toolbox-3.6.x.*` store path and `jetbrains-toolbox --version` prints the new version. Running IDEs are unaffected (they read from `~/.local/share/JetBrains/Toolbox/apps/`).
- **Out of scope / known limitation**: Toolbox will still be unable to self-update in place (it lives in `/nix/store`). Recurrence is structural: each new upstream release requires another `nix flake update --input nixpkgs-unstable`. This tradeoff is accepted by choosing the nix-managed path (Option 1) over a self-managed out-of-nix install (Option 3, not chosen).