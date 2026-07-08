# Declarative herdr config.toml generated from Nix attrsets via pkgs.formats.toml.
# Consumed in home-manager/home.nix.

{ config, pkgs, ... }:

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
in
{
  xdg.configFile."herdr/config.toml".source =
    (pkgs.formats.toml { }).generate "herdr-config" herdrConfig;
}
