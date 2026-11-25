# Proposal

## Why

The Nix-managed user environment includes the GitHub Copilot CLI but not GitHub's desktop app. A pinned Home Manager installation will make the desktop app available from the application grid while preserving the existing CLI setup.

## What Changes

- Add a custom Nix package for GitHub's official Linux x86_64 desktop-app AppImage, pinned to an upstream version and hash and integrated with a desktop entry and icon.
- Expose the package through the existing custom-package overlay and flake package outputs, then install it through the Home Manager AI module.
- Provide the OpenSSL-backed `libcurl` ABI required by the app's Git HTTPS helper, without changing system-wide library settings.
- Leave the existing Copilot CLI, Neovim integration, NixOS AppImage settings, and flake inputs unchanged.

## Capabilities

### New Capabilities

- `github-copilot-app`: Declaratively package and install the official desktop app and make it launchable from the desktop application grid.

### Modified Capabilities

None.

## Impact

- Package definition and exports: `pkgs/github-copilot-app.nix`, `pkgs/default.nix`, and the existing additions overlay.
- User installation: `home-manager/ai.nix`.
- Validation: build the package, inspect its FHS `libcurl` ABI, and run the existing Home Manager build; confirm an HTTPS repository clone after activation. No flake input update or system-level AppImage configuration change is expected.
