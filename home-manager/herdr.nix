# Writable herdr config.toml bootstrapped from Nix attrsets via pkgs.formats.toml.
# Copied on first activation (or if file is a legacy symlink) instead of symlinked
# to the Nix store, so settings can be tested quickly via `herdr server reload-config`
# before incorporating them back into this module.
#
# Reset to baseline:
#   cp ~/.config/herdr/config.toml ~/.config/herdr/config.toml.bak
#   rm ~/.config/herdr/config.toml
#   home-manager switch

{ config, lib, pkgs, ... }:

let
  herdrConfig = {
    onboarding = false;
    keys.prefix = "`";
    theme = {
      name = "one-dark";
      auto_switch = false;
    };
    ui = {
      agent_panel_sort = "spaces";
      show_agent_labels_on_pane_borders = true;
      toast = {
        delivery = "system";
      };
    };
  };

  herdrConfigToml = (pkgs.formats.toml { }).generate "herdr-config" herdrConfig;
in
{
  home.activation.copyHerdrConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/.config/herdr/config.toml"
    if [ ! -f "$target" ] || [ -L "$target" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$target")"
      $DRY_RUN_CMD cp ${herdrConfigToml} "$target"
    fi
  '';
}
