## Context

This NixOS configuration manages a single machine (`nixos-vmware`).
User packages are declared in `home-manager/home.nix` under `home.packages`.
There is no existing Nix language server installed.

## Goals / Non-Goals

**Goals:**
- Make `nil` and `nixd` available in the user environment so any editor can use them.
- Keep the change minimal and self-contained.

**Non-Goals:**
- Configuring Neovim LSP settings to auto-start these servers.
- Removing or replacing any existing tooling.
- Adding language server configuration files (`.nixd.json`, etc.).

## Decisions

1. **Install via Home Manager `home.packages`**
   - *Rationale*: This is a single-user machine (`tung`). Language servers are primarily used by the primary user in editors like Neovim and Zed. Installing via Home Manager keeps user-level developer tooling together and avoids unnecessary system rebuilds.
   - *Alternative considered*: System packages in `environment.systemPackages`. Rejected because `home.packages` is the established pattern for the user's dev tooling in this config (see `php.nix`, `go.nix`, `node.nix`).

2. **Add to `home.packages` in `home-manager/home.nix`**
   - *Rationale*: This is the canonical location for user-level packages in this flake.
   - *Alternative considered*: Creating a dedicated module. Rejected as overkill for two package additions.

## Risks / Trade-offs

- [Closure size] → Both packages are relatively small; impact is negligible.
- [Conflict] → `nil` and `nixd` are independent implementations; they can coexist.
