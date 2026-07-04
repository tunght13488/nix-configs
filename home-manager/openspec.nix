# Links OpenSpec agent integration files (skills, prompts, commands) generated
# by pkgs/openspec-agent-files.nix into global Pi and OpenCode config directories.
#
# Consumed in home-manager/home.nix.

{ pkgs, lib, ... }:

let
  inherit (pkgs) openspecAgentFiles;
  mkSource = path: lib.mkDefault "${openspecAgentFiles}${path}";
in
{
  home.file = {
    # Pi skills
    ".pi/agent/skills/openspec-apply-change/SKILL.md".source =
      mkSource "/.pi/skills/openspec-apply-change/SKILL.md";
    ".pi/agent/skills/openspec-archive-change/SKILL.md".source =
      mkSource "/.pi/skills/openspec-archive-change/SKILL.md";
    ".pi/agent/skills/openspec-bulk-archive-change/SKILL.md".source =
      mkSource "/.pi/skills/openspec-bulk-archive-change/SKILL.md";
    ".pi/agent/skills/openspec-continue-change/SKILL.md".source =
      mkSource "/.pi/skills/openspec-continue-change/SKILL.md";
    ".pi/agent/skills/openspec-explore/SKILL.md".source =
      mkSource "/.pi/skills/openspec-explore/SKILL.md";
    ".pi/agent/skills/openspec-ff-change/SKILL.md".source =
      mkSource "/.pi/skills/openspec-ff-change/SKILL.md";
    ".pi/agent/skills/openspec-new-change/SKILL.md".source =
      mkSource "/.pi/skills/openspec-new-change/SKILL.md";
    ".pi/agent/skills/openspec-onboard/SKILL.md".source =
      mkSource "/.pi/skills/openspec-onboard/SKILL.md";
    ".pi/agent/skills/openspec-propose/SKILL.md".source =
      mkSource "/.pi/skills/openspec-propose/SKILL.md";
    ".pi/agent/skills/openspec-sync-specs/SKILL.md".source =
      mkSource "/.pi/skills/openspec-sync-specs/SKILL.md";
    ".pi/agent/skills/openspec-verify-change/SKILL.md".source =
      mkSource "/.pi/skills/openspec-verify-change/SKILL.md";

    # Pi prompts
    ".pi/agent/prompts/opsx-apply.md".source =
      mkSource "/.pi/prompts/opsx-apply.md";
    ".pi/agent/prompts/opsx-archive.md".source =
      mkSource "/.pi/prompts/opsx-archive.md";
    ".pi/agent/prompts/opsx-bulk-archive.md".source =
      mkSource "/.pi/prompts/opsx-bulk-archive.md";
    ".pi/agent/prompts/opsx-continue.md".source =
      mkSource "/.pi/prompts/opsx-continue.md";
    ".pi/agent/prompts/opsx-explore.md".source =
      mkSource "/.pi/prompts/opsx-explore.md";
    ".pi/agent/prompts/opsx-ff.md".source =
      mkSource "/.pi/prompts/opsx-ff.md";
    ".pi/agent/prompts/opsx-new.md".source =
      mkSource "/.pi/prompts/opsx-new.md";
    ".pi/agent/prompts/opsx-onboard.md".source =
      mkSource "/.pi/prompts/opsx-onboard.md";
    ".pi/agent/prompts/opsx-propose.md".source =
      mkSource "/.pi/prompts/opsx-propose.md";
    ".pi/agent/prompts/opsx-sync.md".source =
      mkSource "/.pi/prompts/opsx-sync.md";
    ".pi/agent/prompts/opsx-verify.md".source =
      mkSource "/.pi/prompts/opsx-verify.md";
  };

  xdg.configFile = {
    # OpenCode skills
    "opencode/skills/openspec-apply-change/SKILL.md".source =
      mkSource "/.opencode/skills/openspec-apply-change/SKILL.md";
    "opencode/skills/openspec-archive-change/SKILL.md".source =
      mkSource "/.opencode/skills/openspec-archive-change/SKILL.md";
    "opencode/skills/openspec-bulk-archive-change/SKILL.md".source =
      mkSource "/.opencode/skills/openspec-bulk-archive-change/SKILL.md";
    "opencode/skills/openspec-continue-change/SKILL.md".source =
      mkSource "/.opencode/skills/openspec-continue-change/SKILL.md";
    "opencode/skills/openspec-explore/SKILL.md".source =
      mkSource "/.opencode/skills/openspec-explore/SKILL.md";
    "opencode/skills/openspec-ff-change/SKILL.md".source =
      mkSource "/.opencode/skills/openspec-ff-change/SKILL.md";
    "opencode/skills/openspec-new-change/SKILL.md".source =
      mkSource "/.opencode/skills/openspec-new-change/SKILL.md";
    "opencode/skills/openspec-onboard/SKILL.md".source =
      mkSource "/.opencode/skills/openspec-onboard/SKILL.md";
    "opencode/skills/openspec-propose/SKILL.md".source =
      mkSource "/.opencode/skills/openspec-propose/SKILL.md";
    "opencode/skills/openspec-sync-specs/SKILL.md".source =
      mkSource "/.opencode/skills/openspec-sync-specs/SKILL.md";
    "opencode/skills/openspec-verify-change/SKILL.md".source =
      mkSource "/.opencode/skills/openspec-verify-change/SKILL.md";

    # OpenCode commands
    "opencode/commands/opsx-apply.md".source =
      mkSource "/.opencode/commands/opsx-apply.md";
    "opencode/commands/opsx-archive.md".source =
      mkSource "/.opencode/commands/opsx-archive.md";
    "opencode/commands/opsx-bulk-archive.md".source =
      mkSource "/.opencode/commands/opsx-bulk-archive.md";
    "opencode/commands/opsx-continue.md".source =
      mkSource "/.opencode/commands/opsx-continue.md";
    "opencode/commands/opsx-explore.md".source =
      mkSource "/.opencode/commands/opsx-explore.md";
    "opencode/commands/opsx-ff.md".source =
      mkSource "/.opencode/commands/opsx-ff.md";
    "opencode/commands/opsx-new.md".source =
      mkSource "/.opencode/commands/opsx-new.md";
    "opencode/commands/opsx-onboard.md".source =
      mkSource "/.opencode/commands/opsx-onboard.md";
    "opencode/commands/opsx-propose.md".source =
      mkSource "/.opencode/commands/opsx-propose.md";
    "opencode/commands/opsx-sync.md".source =
      mkSource "/.opencode/commands/opsx-sync.md";
    "opencode/commands/opsx-verify.md".source =
      mkSource "/.opencode/commands/opsx-verify.md";
  };
}
