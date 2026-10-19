# Design

## Context

See proposal.md for motivation. The managed user environment is Home Manager on the pinned NixOS 26.05 package set. Herdr, the terminal emulators, and their configuration are declared globally in `home-manager/`, and the user switches between the GNOME default session and the optional Hyprland session. `wl-clipboard` is a long-standing package in the stable nixpkgs channel, so no flake input or overlay change is needed.

## Goals / Non-Goals

**Goals:**

- Provide `wl-copy` and `wl-paste` on PATH in the managed user environment.
- Keep the tools usable in both GNOME and Hyprland sessions with no session gating.

**Non-Goals:**

- Adding a clipboard manager daemon, tray icon, or history persistence.
- Adding X11 clipboard tooling (`xclip`/`xsel`) for non-Wayland contexts.
- Changing herdr, terminal emulator, or tmux configuration.

## Decisions

### Add `wl-clipboard` to the terminal module's package list

Declare `wl-clipboard` in the `home.packages` list of `home-manager/terminal.nix`, alongside the existing terminal utilities (`unzip`, `pv`, `dnsutils`). The consumer of this capability is a terminal tool (herdr's click-to-copy), and the module already collects terminal-adjacent CLI utilities. A new module for one package would add fragmentation.

Alternative considered: `home-manager/home.nix` global package list, where `herdr` itself is declared. Rejected because that list is for user-facing applications, while `terminal.nix` is the established home for terminal utilities. Alternative considered: `home-manager/hyprland.nix` — rejected because the requirement is session-independent (GNOME must work too) and that module is gated Hyprland-only by design.

### Use the stable `pkgs.wl-clipboard` package

The pinned `nixos-26.05` channel provides `wl-clipboard` with the `wl-copy` and `wl-paste` binaries. Using the stable package matches the repository's pattern of preferring stable packages and adding `unstable.` entries only for bleeding-edge needs.

Alternative considered: `pkgs.unstable.wl-clipboard` — rejected; there is no bleeding-edge requirement for clipboard CLI tools.

### No services, no keybindings, no config

The package provides plain CLI tools and needs no daemon, unit, or configuration file. This mirrors how `dnsutils` and `pv` are handled in the same module.

## Risks / Trade-offs

- [Copy fails when no Wayland socket is available (SSH session, non-graphical login)] → The tools fail with a clear error; this is expected CLI behavior and does not affect other configuration. Out of scope.
- [GNOME already provides clipboard services] → `wl-clipboard` only adds CLI tools and does not register any competing service, so GNOME behavior is unchanged.
- [Hyprland clipboard requires a running compositor with `wlr-data-control` or seat protocol support] → Hyprland supports the wlroots data-control protocol; the UWSM and regular sessions both run the same compositor, so no session-specific handling is needed.

## Migration Plan

1. Add `wl-clipboard` to the `home.packages` list in `home-manager/terminal.nix`.
2. Format the file and run `make home-build` without activating a generation.
3. Have the user activate the Home Manager generation while retaining the previous generation for rollback.
4. Verify `wl-copy`/`wl-paste` on PATH and a round-trip copy/paste in the GNOME session; repeat in a Hyprland session.
5. Verify herdr's click-to-copy succeeds in both sessions.
6. Rollback: remove the package from the list and apply the previous Home Manager generation.
