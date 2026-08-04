# Herdr agent skill file (SKILL.md) for Pi and OpenCode.
#
# Copies SKILL.md from the herdr flake source into agent-specific
# directory layouts so it can be linked into ~/.pi/ and ~/.config/opencode/
# by home-manager.
#
# v0.8.0 moved SKILL.md from the repo root to skills/herdr/SKILL.md.
#
# Consumed by home-manager/herdr.nix.

{ runCommand, herdrSrc }:

runCommand "herdr-agent-files" { } ''
  mkdir -p $out/.pi/skills/herdr
  ln -s ${herdrSrc}/skills/herdr/SKILL.md $out/.pi/skills/herdr/SKILL.md

  mkdir -p $out/.opencode/skills/herdr
  ln -s ${herdrSrc}/skills/herdr/SKILL.md $out/.opencode/skills/herdr/SKILL.md
''
