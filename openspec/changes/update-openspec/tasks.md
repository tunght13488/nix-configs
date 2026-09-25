## 1. Bump agent-files derivation

- [x] 1.1 In `pkgs/openspec-agent-files.nix`, set `version = "1.13.2"` and replace the `fetchFromGitHub` `hash` with the fake hash; run `nix build .#openspecAgentFiles` (or `make home-build`) and paste the hash Nix reports. Done when the build succeeds with the real hash in place.
- [x] 1.2 Inspect the built output: `ls result/.pi/prompts result/.pi/skills result/.opencode/commands result/.opencode/skills` each contain exactly the same 12 workflow entries as before. Done when counts are 12/12/12/12 with no new or missing names.

## 2. Bump CLI override

- [x] 2.1 In `overlays/default.nix` (`unstable.openspec` overrideAttrs), set `version`/`tag` to `1.13.2`/`v1.13.2`, replace both the `fetchFromGitHub` `hash` and the `fetchPnpmDeps` `hash` with fake hashes, and update `pnpmDeps` `version` to `1.13.2`; rebuild and paste the hashes Nix reports (two iterations: src hash first, then pnpmDeps hash). Done when `nix build .#homeConfigurations."tung@nixos-vmware".activationPackage` (via `make home-build`) evaluates the override without hash mismatches.
- [x] 2.2 If `fetchPnpmDeps` fails on a lockfile/pnpm-version error rather than a hash mismatch, inspect the v1.13.2 `pnpm-lock.yaml` and adjust the pinned `pnpm` input accordingly. Done when the pnpm deps fetch succeeds (skip and check off if 2.1 already succeeded).

## 3. Verify

- [x] 3.1 Run `make home-build`. Done when it completes with no errors and no references to missing files in `home-manager/openspec.nix`.
- [x] 3.2 Verify the built CLI reports the new version (e.g. `nix eval --raw .#homeConfigurations."tung@nixos-vmware".pkgs.unstable.openspec.version` or run the built `openspec --version`). Done when it reports `1.13.2`.
- [x] 3.3 Run `openspec validate update-openspec --strict` for this change's artifacts. Done when it reports valid.
- [x] 3.4 Report to the user that activation requires `make home` (run by the user, not the agent).
