## 1. Update flake input

- [x] 1.1 Change `inputs.herdr.url` from `github:ogulcancelik/herdr/v0.7.5` to `github:herdrdev/herdr/v0.8.0` in `flake.nix`
- [x] 1.2 Run `nix flake lock --update-input herdr` to regenerate the `flake.lock` herdr entry
- [x] 1.3 Run `nix flake check --no-write-lock-file` to validate flake evaluation

## 2. Fix agent-skill derivation source path

- [x] 2.1 In `pkgs/herdr-agent-files.nix`, change the symlinked source from `${herdrSrc}/SKILL.md` to `${herdrSrc}/skills/herdr/SKILL.md` (both the `.pi/skills/herdr` and `.opencode/skills/herdr` links)
- [x] 2.2 Confirm `${herdrSrc}/skills/herdr/SKILL.md` exists in the v0.8.0 flake source tree (e.g. via `nix build .#herdrAgentFiles` or inspecting `inputs.herdr.outPath`)

## 3. Verify build

- [x] 3.1 Run `make home-build` to verify home-manager configuration evaluates with the new herdr version and the updated agent-skill derivation builds
- [x] 3.2 Confirm no unknown config key warnings from v0.8.0's config validation (the baseline keys remain valid; new optional keys `ui.pane_scrollbars` and `ui.tab_bar_position` are intentionally not adopted)

## 4. Verify `herdr --skill` and agent skill files

- [x] 4.1 Confirm `pkgs.herdrAgentFiles` derivation builds and produces `$out/.pi/skills/herdr/SKILL.md` and `$out/.opencode/skills/herdr/SKILL.md` from the new source path
- [x] 4.2 Spot-check that the v0.8.0 binary's `herdr --skill` prints the bundled skill (verifies the upstream Nix package bundles `skills/herdr/SKILL.md` per #1889)