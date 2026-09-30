# Tasks

## 1. Update herdr flake input

- [x] 1.1 In `flake.nix`, change `herdr.url` from `github:herdrdev/herdr/v0.9.2` to `github:herdrdev/herdr/v0.9.3`; verify `git diff flake.nix` shows only that one-line change
- [x] 1.2 Run `nix flake update herdr` to refresh only the herdr input in `flake.lock`; verify `jq -r '.nodes.herdr.original.ref' flake.lock` prints `v0.9.3` and `git diff flake.lock` touches only the `herdr` node (and its `nixpkgs_2`/`rust-overlay` follows if upstream re-pinned them)

## 2. Verify

- [x] 2.1 Run `make home-build` and verify the home-manager configuration builds successfully (this also realizes `pkgs.herdrAgentFiles`, confirming `skills/herdr/SKILL.md` still exists at the expected path in the v0.9.3 source)
- [x] 2.2 Run `nix build '.#homeConfigurations."tung@nixos-vmware".config.home.path'` and verify `./result/bin/herdr --version` reports `0.9.3`
- [x] 2.3 Report to the user that the build is verified and ask them to run `make home` to apply (agents must not run `make home` per AGENTS.md)
