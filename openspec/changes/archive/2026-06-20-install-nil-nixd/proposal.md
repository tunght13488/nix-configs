## Why

The NixOS configuration currently lacks language server support for Nix development.
Installing `nil` and `nixd` provides IDE features (completion, diagnostics, go-to-definition)
for `.nix` files across the system, improving the editing experience in Neovim and other
LSP-enabled editors.

## What Changes

- Add `nil` and `nixd` to the user packages in `home-manager/home.nix`.
- No breaking changes. No configuration files or existing services are modified.

## Capabilities

### New Capabilities
- `nix-language-servers`: The user environment provides Nix language servers (`nil` and `nixd`) available for IDE/LSP integration.

### Modified Capabilities
<!-- No existing capabilities have requirement changes. -->
*None*

## Impact

- **User environment**: Adds two packages to the Home Manager profile.
- **Editors**: Neovim (via LSP config) and other editors can now discover `nil`/`nixd`.
- **No API or service impact.**
