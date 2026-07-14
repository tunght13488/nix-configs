## Why

Ghostty is a fast, native GPU-accelerated terminal emulator with modern features (native tabs, splits, ligatures, terminal inspector) not available in Alacritty. Adding it alongside the existing Alacritty setup lets me evaluate it as a potential daily driver without disrupting the working Alacritty configuration.

## What Changes

- Enable `programs.ghostty` via home-manager module with matching font/cursor settings from the existing Alacritty config
- Enable Ghostty's Zsh shell integration
- Alacritty configuration remains untouched — both terminals coexist

## Capabilities

### New Capabilities
- `ghostty-terminal`: Declarative Ghostty terminal emulator configuration via home-manager, installed alongside existing Alacritty

### Modified Capabilities
<!-- No existing capability requirements change -->

## Impact

- **home-manager/terminal.nix**: New `programs.ghostty` block (~10 lines)
- No other files, services, or packages affected
