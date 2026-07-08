## 1. Create herdr agent files derivation

- [x] 1.1 Create `pkgs/herdr-agent-files.nix` — a `runCommand` derivation that copies `${herdrSrc}/SKILL.md` to `$out/.pi/skills/herdr/SKILL.md` and `$out/.opencode/skills/herdr/SKILL.md`, accepting `herdrSrc` as a parameter

## 2. Register in additions overlay

- [x] 2.1 Edit `overlays/default.nix` — add `herdrAgentFiles` to the `additions` overlay, calling `final.callPackage ../pkgs/herdr-agent-files.nix { herdrSrc = inputs.herdr.outPath; }`

## 3. Add skill linking to herdr home-manager module

- [x] 3.1 Edit `home-manager/herdr.nix` — add `home.file` entry for `~/.pi/agent/skills/herdr/SKILL.md` sourced from `pkgs.herdrAgentFiles`, and `xdg.configFile` entry for `opencode/skills/herdr/SKILL.md` sourced from the same derivation, below the existing config bootstrapping block with a clear comment separator

## 4. Verify

- [x] 4.1 Run `nixpkgs-fmt` on all changed `.nix` files
- [x] 4.2 Run `make home-build` to verify home-manager evaluation succeeds
- [x] 4.3 Confirm `~/.pi/agent/skills/herdr/SKILL.md` and `~/.config/opencode/skills/herdr/SKILL.md` exist as expected after `home-manager switch` (user-performed)
