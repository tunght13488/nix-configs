## Context

The nix-configs repository currently uses Alacritty as its sole terminal emulator, configured via `programs.alacritty` in `home-manager/terminal.nix`. Ghostty is available in nixpkgs (both stable 25.11 and unstable at version 1.3.1) and home-manager provides a `programs.ghostty` module with declarative settings, shell integration, and systemd support.

The goal is to add Ghostty alongside Alacritty — not replace it — so the user can evaluate it without disrupting their working setup.

## Goals / Non-Goals

**Goals:**
- Enable Ghostty via home-manager's `programs.ghostty` module
- Configure font (Monaspace Krypton NF) and cursor (bar, no blink) to match existing Alacritty settings
- Enable Zsh shell integration
- Keep Alacritty configuration intact

**Non-Goals:**
- Porting Alacritty color themes to Ghostty (user can do this later)
- Setting up Ghostty-specific keybinds, window decorations, or advanced features
- Replacing Alacritty

## Decisions

**Use `pkgs.ghostty` (stable) rather than `pkgs.unstable.ghostty`**

Both channels carry version 1.3.1 currently. Using the default stable package avoids unnecessary churn. The `package` option makes switching to unstable trivial later if needed.

**Use `programs.ghostty` module rather than raw `home.packages`**

The home-manager module provides:
- Declarative config generation (`$XDG_CONFIG_HOME/ghostty/config`)
- Systemd user service for Linux performance
- Bat syntax highlighting for Ghostty config files
- Zsh shell integration (via `enableZshIntegration`)

This is consistent with how all other terminal tooling is configured in `terminal.nix`.

**Map Alacritty cursor name to Ghostty's equivalent**

Alacritty calls the vertical line cursor `"Beam"`; Ghostty calls it `"bar"`. This is the only terminology difference that matters for the port.

## Risks / Trade-offs

- **Two terminal emulators on PATH** — No risk. They're independent binaries with distinct names (`alacritty` vs `ghostty`). The user chooses which to launch.
- **GTK/libadwaita dependency** — Ghostty pulls in GTK4 on Linux for the titlebar/window decorations. This adds ~50MB of closures. Mitigation: this is a fast, cached build on the nixos-vmware machine.
- **Ghostty config drift from Alacritty config** — If Alacritty settings change later, Ghostty won't automatically follow. Mitigation: this is intentional — they're independent tools serving different evaluation paths.
