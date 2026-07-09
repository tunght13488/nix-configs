# Home-manager module for codebase-memory-mcp.
#
# Installs the pre-built codebase-memory-mcp binary and symlinks a pi skill
# teaching the agent to use CLI-based code discovery tools.
#
# Consumed via inputs.self.homeManagerModules.codebase-memory-mcp
# in home-manager/home.nix.

{ config, lib, pkgs, ... }:

let
  cfg = config.programs.codebase-memory-mcp;
in
{
  options.programs.codebase-memory-mcp = {
    enable = lib.mkEnableOption "codebase-memory-mcp code intelligence";

    package = lib.mkPackageOption pkgs "codebase-memory-mcp" { };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file.".pi/agent/skills/codebase-memory/SKILL.md".source =
      "${cfg.package}/share/pi/skills/codebase-memory/SKILL.md";
  };
}
