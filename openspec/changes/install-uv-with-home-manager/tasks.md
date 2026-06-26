## 1. Add uv to home-manager package list

- [x] 1.1 Add `unstable.uv` as a new entry inside the existing `home.packages = with pkgs; [ ... ]` block in `home-manager/home.nix`, placed adjacent to the existing `unstable.openspec` / `unstable.zed-editor` lines (same style)
- [x] 1.2 `git add` is **not** required (modifying an existing tracked file), but confirm no new file was created under `home-manager/`

## 2. Verify

- [x] 2.1 Run `make home-build` and confirm the home-manager configuration evaluates and builds without errors
- [x] 2.2 Run `nix flake show --no-write-lock-file` and confirm no new `devShells.*` entry was introduced (spec: no Python devShell)
- [x] 2.3 Run `git diff home-manager/tmux.nix` and confirm the output is empty (spec: tmux's nixpkgs `python313` untouched)
- [x] 2.4 Run `git diff home-manager/home.nix` and confirm the change is exactly one new line referencing `unstable.uv` inside the `home.packages` list, with `home.sessionVariables` unchanged
- [x] 2.5 Run `make format` to ensure `home.nix` is formatted per `nixpkgs-fmt`

## 3. Smoke test (user step — do NOT run automatically)

- [ ] 3.1 Prompt the user to run `make home` themselves, then `uv --version` and `uv python install 3.12` to verify runtime behavior