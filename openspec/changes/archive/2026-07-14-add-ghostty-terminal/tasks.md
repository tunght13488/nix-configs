## 1. Configuration

- [x] 1.1 Add `programs.ghostty` block to `home-manager/terminal.nix` with font (Monaspace Krypton NF, 10pt), cursor (bar, no blink), and Zsh integration enabled
- [x] 1.2 Verify no Alacritty settings are accidentally modified or removed

## 2. Validation

- [x] 2.1 Run `make home-build` and confirm evaluation succeeds without errors
- [x] 2.2 Confirm `ghostty` binary appears in the built closure
