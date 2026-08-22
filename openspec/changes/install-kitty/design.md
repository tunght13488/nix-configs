## Context

See proposal.md for the motivation and scope. The user configuration imports `home-manager/terminal.nix`, where Alacritty and Ghostty are already configured from shared `fontFamily` and `fontSize` values. The flake uses the Home Manager `release-26.05` input, whose Kitty module supports enabling the package, setting a font, passing Kitty settings through to `kitty.conf`, and enabling Zsh shell integration.

## Goals / Non-Goals

**Goals:**

- Add Kitty to the existing terminal configuration without introducing a new module or flake input.
- Reuse the existing Monaspace Krypton NF and size 10 values.
- Express the bar, non-blinking cursor through Kitty's supported configuration keys.
- Enable Kitty's Zsh integration explicitly.
- Preserve Alacritty and Ghostty as independently usable terminal emulators.

**Non-Goals:**

- Replacing Alacritty or Ghostty.
- Selecting Kitty as a desktop-wide default terminal.
- Porting color themes, keybindings, window behavior, or other advanced Kitty settings.
- Changing NixOS services or adding a system-level package declaration.

## Decisions

- **Use Home Manager's `programs.kitty` module.** The module installs Kitty when enabled and generates its configuration, while also exposing declarative font, settings, and shell-integration options. Installing only `pkgs.kitty` through `home.packages` would not provide the managed configuration or integration wiring. The module is already the established pattern for Alacritty and Ghostty in this file.

- **Place the configuration in `home-manager/terminal.nix`.** This keeps all terminal emulator declarations together and allows Kitty to reuse the existing `fontFamily` and `fontSize` bindings. Creating a separate module would add indirection for a single terminal declaration.

- **Use the default stable `pkgs.kitty` package.** The flake's primary nixpkgs input is the pinned `nixos-26.05` channel, and Kitty does not require a separate unstable package or input. This minimizes dependency and closure churn; switching channels later remains a local package-option change if needed.

- **Map the shared cursor baseline to Kitty settings.** Kitty represents the bar cursor with `cursor_shape = "beam"` and disables blinking with `cursor_blink_interval = 0`. These settings are passed through the module's `settings` attribute set, while the module's `font` option manages the font family and size.

- **Enable Zsh integration explicitly.** `programs.kitty.shellIntegration.enableZshIntegration = true` makes the intended interactive-shell behavior clear and keeps it stable if Home Manager defaults change.

## Risks / Trade-offs

- **Kitty increases the Home Manager closure size.** Kitty brings its own runtime dependencies. Mitigation: use the pinned stable package and verify the Home Manager build before applying the generation.

- **Kitty's generated Zsh integration changes shell initialization for Kitty sessions.** Mitigation: the integration is limited to Zsh initialization and does not alter Alacritty or Ghostty configuration; verify the generated Home Manager configuration and an interactive Kitty session after applying.

- **The shared font may not be available outside the current managed profile.** Mitigation: the repository already installs Monaspace and its Nerd Font variant through Home Manager, and the build should confirm the referenced font declaration evaluates successfully.

- **Cursor terminology differs between terminal emulators.** Mitigation: validate the generated `kitty.conf` contains the Kitty-specific `cursor_shape` and `cursor_blink_interval` values rather than assuming Alacritty or Ghostty option names carry over.

## Migration Plan

1. Add the Kitty block to `home-manager/terminal.nix`.
2. Run `make home-build` to evaluate and build the Home Manager configuration without activating it.
3. Apply the generation through the user's normal Home Manager workflow, then verify `kitty --version`, `kitten --version`, the generated Kitty configuration, and Zsh integration.
4. To roll back, remove the Kitty block and apply a subsequent Home Manager generation, or select the previous Home Manager generation; existing Alacritty and Ghostty declarations require no migration.
