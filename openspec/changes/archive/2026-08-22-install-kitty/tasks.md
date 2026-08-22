## 1. Add Kitty to the terminal configuration

- [x] 1.1 Add a `programs.kitty` declaration to `home-manager/terminal.nix` that enables Kitty and reuses the existing `fontFamily` and `fontSize` bindings.
- [x] 1.2 Configure Kitty's bar cursor and disabled blinking through its supported settings, and explicitly enable Zsh shell integration.
- [x] 1.3 Confirm the Alacritty and Ghostty declarations and their existing settings remain unchanged.

## 2. Validate the Home Manager configuration

- [x] 2.1 Format the updated Nix file with `nixpkgs-fmt` or `make format` and confirm it remains clean.
- [x] 2.2 Run `make home-build` and confirm the Home Manager configuration evaluates and builds successfully.
- [x] 2.3 Inspect the built Home Manager output to confirm Kitty and `kitten` are present and the generated Kitty configuration contains the requested font, cursor, and shell-integration settings.

## 3. Verify after activation

- [x] 3.1 Apply the built Home Manager generation using the user's normal activation workflow.
- [x] 3.2 Run `kitty --version` and `kitten --version`, then start a Kitty Zsh session to verify the commands, visual baseline, and shell integration work as specified.
