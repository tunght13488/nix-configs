## 1. Bump agent-files derivation to v1.8.0

- [ ] 1.1 In `pkgs/openspec-agent-files.nix`, change `version` from `1.5.0` to `1.8.0` and `rev` from `v${version}` (resolves to `v1.8.0`)
- [ ] 1.2 Set the `fetchFromGitHub` `hash` to `sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=` (libfakehash), run `nix build .#openspecAgentFiles` to obtain the correct hash from the error output, and paste the real hash back in
- [ ] 1.3 Confirm `pkgs/generate-agent-files.mjs` import paths still resolve against v1.8.0 source; if esbuild fails on a renamed/moved module, update the import in `generate-agent-files.mjs` to the v1.8.0 path
- [ ] 1.4 Build the derivation with `nix build .#openspecAgentFiles` and confirm it produces `.pi/` and `.opencode/` output

## 2. Bump the CLI override to v1.8.0

- [ ] 2.1 In `overlays/default.nix`, change the `unstable.openspec` `overrideAttrs` `version` from `1.5.0` to `1.8.0` and `tag` from `v1.5.0` to `v1.8.0`
- [ ] 2.2 Set the `fetchFromGitHub` `hash` in the override to the libfakehash, run `nix build .#unstable.openspec` to obtain the correct hash, and paste it back in
- [ ] 2.3 Set the `fetchPnpmDeps` `hash` to the libfakehash, rerun the build to obtain the correct `pnpmDeps` hash, and paste it back in; if the build fails on lockfile/pnpm version, bump the pinned `pnpm = final'.pnpm_11` to the version v1.8.0 requires
- [ ] 2.4 Confirm `nix build .#unstable.openspec` succeeds and the resulting `openspec --version` reports `1.8.0`

## 3. Wire in the new `update` workflow links

- [ ] 3.1 Inspect the built `openspecAgentFiles` output to confirm the exact directory name for the new skill (expected `openspec-update-change`) and the prompt/command filename (expected `opsx-update.md`)
- [ ] 3.2 In `home-manager/openspec.nix`, append a `.pi/agent/prompts/opsx-update.md` `home.file` entry sourcing `${openspecAgentFiles}/.pi/prompts/opsx-update.md` after the `opsx-verify.md` entry
- [ ] 3.3 Append a `.pi/agent/skills/openspec-update-change/SKILL.md` `home.file` entry after the `openspec-verify-change` entry
- [ ] 3.4 Append an `opencode/commands/opsx-update.md` `xdg.configFile` entry after the `opsx-verify.md` command entry
- [ ] 3.5 Append an `opencode/skills/openspec-update-change/SKILL.md` `xdg.configFile` entry after the `openspec-verify-change` skill entry

## 4. Verify and format

- [ ] 4.1 Run `make home-build` and confirm the home-manager build succeeds with all link entries resolving
- [ ] 4.2 Run `make format` (nixpkgs-fmt) on the edited `.nix` files
- [ ] 4.3 Re-run `make home-build` after formatting to confirm it still builds
- [ ] 4.4 Stop without running `make home`; ask the user to run `make home` to activate
