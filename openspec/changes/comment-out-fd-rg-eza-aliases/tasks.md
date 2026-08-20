# Tasks: comment-out-fd-rg-eza-aliases

## 1. Disable aliases

- [x] 1.1 In `home-manager/zsh.nix`, comment out `grep = "rg";` in `programs.zsh.shellAliases`
- [x] 1.2 In `home-manager/zsh.nix`, comment out `ls = "eza --group-directories-first";`
- [x] 1.3 In `home-manager/zsh.nix`, comment out `find = "fd";`
- [x] 1.4 Leave `cat`, `du`, `l`, `la`, and all other aliases unchanged

## 2. Update documentation

- [x] 2.1 In `AGENTS.md`, remove the `find` → `fd`, `grep` → `rg`, and `ls` → `eza` rows from the "Shell Aliases" table, keeping the `cat` and `du` rows

## 3. Verify

- [x] 3.1 Run `make home-build` and confirm it succeeds
- [x] 3.2 Confirm `zsh.nix` still formats cleanly (`nixpkgs-fmt --check home-manager/zsh.nix` or `make format`)
