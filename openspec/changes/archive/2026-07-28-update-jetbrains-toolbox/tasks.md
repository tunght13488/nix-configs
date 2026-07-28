## 1. Package source swap

- [x] 1.1 In `home-manager/home.nix`, replace `jetbrains-toolbox` with `unstable.jetbrains-toolbox` in the `home.packages = with pkgs; [ ... ]` block (keep list ordering/style consistent with the existing `unstable.*` entries)
- [x] 1.2 Confirm no other reference to the 25.11 `jetbrains-toolbox` attribute remains in `home.nix` (rg `jetbrains-toolbox` in `home-manager/`)

## 2. Targeted flake.lock bump

- [x] 2.1 Run `nix flake update nixpkgs-unstable`
- [x] 2.2 Review `git diff flake.lock` and confirm ONLY the `nixpkgs-unstable` node changed (`nixpkgs`, `home-manager`, `nixvim`, `agenix`, `nix-index-database`, `phps` byte-identical to prior commit)

## 3. Verification (eval/build only — AI agents MUST NOT run `make home`)

- [x] 3.1 Run `make home-build` and confirm the home-manager configuration evaluates and builds without errors
- [x] 3.2 Confirm the built package version: inspect the store path / `jetbrains-toolbox --version` resolves to `3.6.2.85969` or newer (satisfies spec scenario "Resolved version tracks a current upstream build")

## 4. Spec-scenario cross-check

- [x] 4.1 Verify spec scenario "Only the unstable input moves": `git diff flake.lock` shows no changes outside the `nixpkgs-unstable` node
- [x] 4.2 Verify spec scenario "Package entry resolves to the unstable input": the `home.nix` diff shows `jetbrains-toolbox` -> `unstable.jetbrains-toolbox`
- [x] 4.3 Verify spec scenario "IDE state is untouched": `~/.local/share/JetBrains/Toolbox/apps/` contents are unchanged by the build (no nix-managed IDE paths introduced)

## 5. Handoff

- [x] 5.1 Commit the `home.nix` change + `flake.lock` bump with a clear message (no emojis per AGENTS.md)
- [x] 5.2 Ask the user to run `make home` to apply (AI agents do not run `make home` / `nixos-rebuild switch`)
- [x] 5.3 Post-apply runtime verification: `which jetbrains-toolbox` resolves to a `*-jetbrains-toolbox-3.6.x.*` store path and `jetbrains-toolbox --version` prints the new version