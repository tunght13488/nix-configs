# Keep the legacy Herdr TUI configured alongside Herdr App/Core.
{ inputs, lib, pkgs, ... }:

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
      toast.delivery = "system";
    };
  };

  herdrConfigToml = (pkgs.formats.toml { }).generate "herdr-config" herdrConfig;
  herdrTuiGuide = "${inputs.herdr.outPath}/skills/herdr/SKILL.md";
  herdrAppGuide = pkgs.herdr-app.agentGuide;
in
{
  home.activation.copyHerdrConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/.config/herdr/config.toml"
    if [ ! -f "$target" ] || [ -L "$target" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$target")"
      $DRY_RUN_CMD cp ${herdrConfigToml} "$target"
    fi
  '';

  home.file = {
    ".pi/agent/skills/herdr/SKILL.md".source = lib.mkDefault herdrTuiGuide;
    ".pi/agent/skills/herdr-app/SKILL.md".source = lib.mkDefault herdrAppGuide;
  };

  xdg.configFile = {
    "opencode/skills/herdr/SKILL.md".source = lib.mkDefault herdrTuiGuide;
    "opencode/skills/herdr-app/SKILL.md".source = lib.mkDefault herdrAppGuide;
  };
}
