## 1. Pin the Herdr release

- [x] 1.1 Update `inputs.herdr.url` in `flake.nix` from the v0.9.0 tag to `github:herdrdev/herdr/v0.9.1`.
- [x] 1.2 Run `nix flake lock --update-input herdr` and review `flake.lock` so only the Herdr revision and dependencies required by that input change.

## 2. Verify packaging and configuration compatibility

- [x] 2.1 Confirm the v0.9.1 flake still exposes `overlays.default`, the `herdr` package, `nix/package.nix`, and `skills/herdr/SKILL.md`; update `pkgs/herdr-agent-files.nix` only if an upstream path changed.
- [x] 2.2 Run `make home-build` to evaluate and build the home-manager configuration with the v0.9.1 package.
- [x] 2.3 Validate the generated Herdr baseline with the v0.9.1 binary's config checker, including the existing theme, prefix, panel, and toast settings; make only minimal compatibility corrections if a current setting is rejected, then repeat the build.
- [x] 2.4 Verify the built agent-files output contains both `.pi/skills/herdr/SKILL.md` and `.opencode/skills/herdr/SKILL.md` with content sourced from v0.9.1.
- [x] 2.5 Review the final diff to confirm tmux configuration, unrelated flake inputs, and unrelated Herdr features remain unchanged.

## 3. Activate and validate the upgrade

- [x] 3.1 Have the user run `home-manager switch` to activate the built generation and preserve the existing writable-config bootstrap behavior.
- [x] 3.2 Confirm `herdr --version` reports v0.9.1 and the command remains available through the home-manager PATH.
- [x] 3.3 Run Herdr config validation against the live `~/.config/herdr/config.toml` and verify both global skill links resolve and contain the v0.9.1 skill.
- [x] 3.4 If activation or runtime checks fail, restore the v0.9.0 input and matching lock state, rebuild, and retain the previous working generation. (Condition not triggered — 3.2 and 3.3 passed, so no rollback was performed; the v0.9.0 baseline lock remains saved in `.tmp/flake.lock.v0.9.0.baseline`.)
