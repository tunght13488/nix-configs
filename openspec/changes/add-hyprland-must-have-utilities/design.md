## Context

See proposal.md for the motivation and scope. The host uses the pinned NixOS 26.05 package set and already enables `programs.hyprland` with UWSM while retaining GDM and GNOME as the explicit default session. The NixOS Hyprland module already supplies Hyprland, XWayland, the Hyprland XDG desktop portal, and the system PolicyKit daemon; GNOME already supplies PipeWire and WirePlumber.

Home Manager currently manages Kitty, Monaspace, and the Monaspace Nerd Font, but no Hyprland configuration, notification daemon, or Hyprland-specific PolicyKit agent. An unmanaged `~/.config/hypr/hyprland.lua` is present from the initial Hyprland session test. The earlier Hyprland change deliberately avoided making Home Manager the owner of that configuration file.

## Goals / Non-Goals

**Goals:**

- Add the page's selected Hyprland user-level utilities declaratively.
- Start `fnott` and `hyprpolkitagent` for both regular and UWSM-managed Hyprland sessions.
- Keep those services from starting as active services in GNOME.
- Add explicit Noto, Qt 5 Wayland, and Qt 6 Wayland support to the managed user environment.
- Preserve the existing unmanaged Hyprland configuration and the current NixOS session integration.

**Non-Goals:**

- Enabling Home Manager's full `wayland.windowManager.hyprland` module or taking ownership of `~/.config/hypr/hyprland.lua`.
- Adding a bar, launcher, wallpaper manager, lock screen, clipboard manager, keybindings, or other desktop-shell components.
- Installing alternative notification daemons or changing GNOME's desktop services.
- Re-declaring PipeWire, WirePlumber, XDG desktop portals, XWayland, or the system PolicyKit daemon already supplied by existing modules.

## Decisions

### Use Home Manager's native service modules

Enable `services.fnott` and `services.hyprpolkitagent` instead of adding imperative startup commands or hand-written user units. The Home Manager release pinned by this repository provides these modules: the fnott module installs its package, generated configuration, D-Bus activation, and user service; the hyprpolkitagent module creates a user service that starts the agent executable. This follows the repository's declarative service pattern and gives both services lifecycle management through systemd.

No custom fnott settings are required for the initial capability. Its package defaults provide a functional notification daemon while leaving appearance decisions for a later desktop-configuration change.

### Gate service startup using the session environment

Home Manager's Wayland service modules normally attach to `graphical-session.target`. The service units are conditioned on `XDG_CURRENT_DESKTOP=Hyprland` in the systemd user manager environment.

During implementation this decision was corrected: the UWSM design deliberately never sets `WAYLAND_DISPLAY` in the user manager environment (it belongs to uwsm's `always_unset` set and is delivered per-unit via `EnvironmentFile=`), so keeping fnott's module-default `WAYLAND_DISPLAY` condition — as originally planned — would make the gate unsatisfiable in the primary UWSM session. That condition is therefore overridden with `lib.mkForce` and the gate uses the Hyprland session variable alone.

UWSM exports `XDG_CURRENT_DESKTOP` to the user manager (uwsm `always_export`), both Hyprland GDM desktop entries identify the session as `Hyprland`, and the GNOME session's manager environment carries `XDG_CURRENT_DESKTOP=GNOME` and fails the condition. This keeps the services usable from both GDM entries where the variable is present, while GNOME continues using its own notification and authentication components.

### Do not enable Home Manager's Hyprland window-manager module

The Home Manager Hyprland module would be a convenient way to create a Hyprland-specific systemd target, but enabling it would also make Home Manager generate and potentially own a Hyprland configuration file. That would conflict with the current test arrangement, where the user already has an unmanaged Lua configuration and the earlier change intentionally deferred declarative Hyprland configuration.

Using unit conditions instead of `wayland.systemd.target = "hyprland-session.target"` preserves the existing configuration boundary and supports both the regular and UWSM-managed sessions. If a later change adopts a fully declarative Hyprland configuration, these services can be moved to that configuration's session target.

### Keep the additional packages in Home Manager

Add `noto-fonts`, `qt5.qtwayland`, and `qt6.qtwayland` to the managed user environment. The Nix package names differ from the names used by the wiki: Qt 5 and Qt 6 support are nested under `pkgs.qt5.qtwayland` and `pkgs.qt6.qtwayland`. `hyprpolkitagent` already depends on Qt 6 Wayland support, but the explicit Qt 6 entry is retained because this change intentionally covers the page's recommendation and the Qt 5 plugin is not supplied by the agent.

The existing `fonts.fontconfig.enable` configuration remains the mechanism for font discovery. Existing Monaspace and Nerd Font packages remain unchanged; Noto is an additional general-purpose fallback rather than a replacement.

### Keep NixOS-owned integration unchanged

Do not add a second portal declaration, PipeWire service, WirePlumber service, or PolicyKit daemon. The existing `programs.hyprland` module has already been evaluated to provide `xdg-desktop-portal-hyprland`, XWayland, and the system PolicyKit daemon, and the current GNOME stack provides PipeWire and WirePlumber. Avoiding duplicate declarations keeps ownership at the layer that already provides each system component.

### Keep related Home Manager changes together

Place the Hyprland-specific service and package declarations in a dedicated `home-manager/hyprland.nix` module and import it from `home-manager/home.nix`. This keeps Hyprland behavior separate from the shared terminal and font modules while leaving the existing Hyprland configuration file unmanaged.

## Risks / Trade-offs

- [The regular Hyprland session does not propagate `XDG_CURRENT_DESKTOP=Hyprland` to the user systemd manager] → Build and test both GDM entries; inspect the user manager environment and adjust the session guard if the regular entry does not start the services.
- [A notification service is accidentally started during GNOME] → Require both Wayland and Hyprland session conditions, then verify that GNOME retains the notification bus and that `fnott` is inactive after a GNOME login.
- [The unmanaged Lua configuration and the new Home Manager module conflict] → Do not enable `wayland.windowManager.hyprland`, do not generate `hyprland.conf`, and limit the new module to packages and conditioned services.
- [Qt 6 Wayland support is already present in the `hyprpolkitagent` closure] → Accept the small amount of explicit package redundancy because the requirement calls for visible Qt 5 and Qt 6 support in the managed environment.
- [Font caches or user services are not refreshed until a new session] → Use Home Manager's existing `sd-switch` behavior and log out/in before evaluating runtime behavior; verify with fontconfig and systemd user-service status.

## Migration Plan

1. Add the dedicated Home Manager module, import it, and declare the selected packages and conditioned services.
2. Format the Nix files and run `make home-build` without activating a generation.
3. Have the user activate the Home Manager generation while retaining the previous generation for rollback.
4. Select `Hyprland (uwsm-managed)` in GDM and verify the fnott notification path, PolicyKit prompt, font discovery, and Qt Wayland behavior.
5. If needed, repeat the checks with the regular `Hyprland` session.
6. Return to GNOME from GDM and verify that the default session, notification daemon, and PolicyKit behavior remain unchanged.
7. If the new generation is unsuitable, roll back the Home Manager generation and retain the existing Hyprland session test configuration.
