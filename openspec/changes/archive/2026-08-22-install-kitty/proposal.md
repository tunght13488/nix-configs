## Why

The Home Manager configuration already provides Alacritty and Ghostty, but Kitty is not available in the managed user environment. Adding Kitty declaratively provides another terminal emulator for evaluation and daily use without requiring an imperative package installation or disturbing the existing terminal setup.

## What Changes

- Enable Kitty through Home Manager's `programs.kitty` module in the shared terminal configuration.
- Configure Kitty with the terminal baseline already used by this configuration: Monaspace Krypton NF at size 10 and a non-blinking bar cursor.
- Enable Kitty's Zsh shell integration for interactive sessions.
- Keep the existing Alacritty and Ghostty installations and settings unchanged; Kitty will be added alongside them rather than replacing either one or becoming an implicit default.

## Capabilities

### New Capabilities

- `kitty-terminal`: Declarative Kitty terminal emulator installation and baseline configuration via Home Manager, coexisting with the existing terminal emulators.

### Modified Capabilities

<!-- No existing capability requirements change. -->

## Impact

- `home-manager/terminal.nix`: adds the Kitty Home Manager configuration.
- The Home Manager user profile gains the `kitty` and `kitten` executables and generated Kitty configuration.
- The configuration closure increases by Kitty and its runtime dependencies.
- No NixOS services, APIs, system-wide defaults, or existing terminal configurations are changed.
