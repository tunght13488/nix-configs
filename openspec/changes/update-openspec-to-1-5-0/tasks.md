## 1. Override OpenSSL CLI to v1.5.0

- [ ] 1.1 Add `openspec` override to `unstable-packages` overlay in `overlays/default.nix`, setting `src` to the v1.5.0 tarball from GitHub
- [ ] 1.2 Set `pnpmDeps` to `lib.fakeHash`, run `make home-build`, and extract the correct hash from the build error
- [ ] 1.3 Update `pnpmDeps` with the correct hash and verify `make home-build` succeeds

## 2. Verify CLI

- [ ] 2.1 Verify `openspec --version` reports `1.5.0` after switching
- [ ] 2.2 Run `openspec schemas` to confirm `workspace-planning` schema is gone and `spec-driven` remains
- [ ] 2.3 Run `openspec list` to confirm existing changes and specs are intact

## 3. Regenerate agent files

- [ ] 3.1 Generate fresh agent files with `openspec init --tools pi,opencode --force` in a temp directory
- [ ] 3.2 Copy generated output into `pkgs/openspec-agent-files/.pi/` and `pkgs/openspec-agent-files/.opencode/`
- [ ] 3.3 Run `git diff pkgs/openspec-agent-files/` to review changes
- [ ] 3.4 Build agent files derivation: `nix build .#openspecAgentFiles` and verify output

## 4. Final build and format

- [ ] 4.1 Run `make home-build` to verify full home-manager evaluation
- [ ] 4.2 Run `make format` to format any modified `.nix` files
- [ ] 4.3 Run `git add` on new/modified files (Nix flakes require tracked files)
