# Hyprland session user utilities: notification daemon, PolicyKit agent,
# Noto fonts, and Qt Wayland support (see
# openspec/changes/add-hyprland-must-have-utilities).
#
# Keep ~/.config/hypr unmanaged: this module does not enable
# wayland.windowManager.hyprland and does not generate a Hyprland config.
#
# The user services are gated on XDG_CURRENT_DESKTOP=Hyprland. UWSM exports
# that variable into the systemd user manager environment (always_export);
# GNOME sets XDG_CURRENT_DESKTOP=GNOME there, so the Hyprland services stay
# inactive during GNOME sessions. WAYLAND_DISPLAY is deliberately NOT part of
# the condition: UWSM always-unsets it from the manager environment, which
# would make the condition unsatisfiable in the primary (UWSM) session.
{ lib
, pkgs
, ...
}:

{
  home.packages = with pkgs; [
    noto-fonts
    qt5.qtwayland
    qt6.qtwayland
  ];

  services.fnott = {
    enable = true;
  };

  services.hyprpolkitagent = {
    enable = true;
  };

  systemd.user.services.fnott.Unit.ConditionEnvironment =
    lib.mkForce "XDG_CURRENT_DESKTOP=Hyprland";
  systemd.user.services.hyprpolkitagent.Unit.ConditionEnvironment =
    "XDG_CURRENT_DESKTOP=Hyprland";
}
