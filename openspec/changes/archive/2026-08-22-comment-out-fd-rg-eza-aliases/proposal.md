# Proposal: comment-out-fd-rg-eza-aliases

## Why

The `find`→`fd`, `grep`→`rg`, and `ls`→`eza` shell aliases shadow the standard POSIX commands in interactive shells. This breaks muscle memory and scripts/snippets pasted into the terminal that expect standard `find`/`grep`/`ls` flag syntax and output formats. Commenting them out (rather than deleting) keeps them easy to re-enable.

## What Changes

- Comment out the `find = "fd";` alias in `home-manager/zsh.nix` (`programs.zsh.shellAliases`).
- Comment out the `grep = "rg";` alias in `home-manager/zsh.nix`.
- Comment out the `ls = "eza --group-directories-first";` alias in `home-manager/zsh.nix`.
- Update the "Shell Aliases" table in `AGENTS.md` to remove the three disabled rows (`find`, `grep`, `ls`), keeping `cat`→`bat` and `du`→`ncdu`.

Assumptions recorded:

- The `cat = "bat ..."` and `du = "ncdu ..."` aliases stay active (not requested for removal).
- The `l = "ls -l"` and `la = "l -a"` aliases stay as-is. Once `ls` is no longer aliased, they resolve to plain `ls -l` / `ls -la` instead of `eza` — accepted behavior change.
- Aliases are commented out, not deleted, so they can be restored later.

## Capabilities

### New Capabilities

- `zsh-shell-aliases`: Interactive shell aliases defined via `programs.zsh.shellAliases` in `home-manager/zsh.nix`, covering which standard commands are shadowed by modern replacements (`fd`, `rg`, `eza`, `bat`, `ncdu`).

### Modified Capabilities

(none)

## Impact

- **Code**: `home-manager/zsh.nix` (`programs.zsh.shellAliases` attrset), `AGENTS.md` (Shell Aliases table).
- **Behavior**: Interactive zsh sessions use real `find`, `grep`, `ls` after the next `make home` / home-manager switch. `l`/`la` fall back to system `ls`. Non-interactive scripts are unaffected (aliases are interactive-only).
- **Dependencies**: `fd`, `ripgrep`, `eza` packages remain installed; only the aliases are disabled.
- **Verification**: `make home-build` must succeed.
