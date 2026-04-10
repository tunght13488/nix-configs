# Copilot instructions for `nix-configs`

## Approach
- Think before acting. Read existing files before writing code.
- Be concise in output but thorough in reasoning.
- Prefer editing over rewriting whole files.
- Do not re-read files you have already read unless the file may have changed.
- Test your code before declaring done.
- No sycophantic openers or closing fluff.
- Keep solutions simple and direct.
- User instructions always override this file.

## Big picture
- This repo is a flake-based personal NixOS setup for `nixos-vmware`; `flake.nix` exposes `nixosConfigurations.nixos-vmware` and standalone `homeConfigurations."tung@nixos-vmware"`.
- Keep the split between host-level NixOS config in `nixos/configuration.nix` and per-user config in `home-manager/home.nix` plus its imported modules.
- Preserve the current minimal layout unless the user asks otherwise: one main system module, one main Home Manager module, and a small set of focused files under `home-manager/`.
- `home-manager/home.nix` imports `inputs.nixvim.homeModules.nixvim`; editor changes usually belong in `home-manager/nixvim.nix`, not a separate Neovim repo.

## Key files
- `flake.nix` pins `nixpkgs`, `home-manager`, and `nixvim` to the `25.11` release family and passes `inputs` into both NixOS and Home Manager.
- `nixos/configuration.nix` owns Nix settings, hostname/timezone, GNOME on X11, VMware guest support, Firefox policies, 1Password GUI, and `environment.systemPackages`.
- `home-manager/home.nix` imports `ssh.nix`, `git.nix`, `zsh.nix`, `tmux.nix`, `fonts.nix`, `terminal.nix`, and `nixvim.nix`.
- `home-manager/zsh.nix` enables Prezto and shell aliases; update this file instead of trying to manage Zsh from `dotfiles/` or the checked-out `prezto/` folder.

## Workflows
- Validate evaluation without touching `flake.lock`: `nix flake show --no-write-lock-file`
- Apply system changes from the repo root: `sudo nixos-rebuild switch --flake .#nixos-vmware`
- Apply user-only changes from the repo root: `home-manager switch --flake .#tung@nixos-vmware`
- If `home-manager` is not installed, use `nix shell nixpkgs#home-manager --command home-manager switch --flake .#tung@nixos-vmware`
- Format touched Nix files with `nixfmt <file>`; `nixfmt` is installed in `environment.systemPackages`.
- Use `.copilot_workspace/` (repo root) as a scratch directory for temporary files, build artefacts, and test outputs instead of `/dev/null` or `/tmp`; it is gitignored and does not require extra approval to write.

## Repo-specific conventions
- Preserve existing identifiers unless requested otherwise: hostname `nixos-vmware`, user `tung`, home directory `/home/tung`, and login shell `pkgs.zsh`.
- Keep ownership clear: system packages, desktop services, users, and Firefox policies belong in `nixos/configuration.nix`; user packages and program settings belong in Home Manager modules.
- Nix is intentionally configured without channels or a global registry; `nix.registry` and `nix.nixPath` are derived from flake inputs in `nixos/configuration.nix`.
- Unfree packages are intentionally enabled broadly (`allowUnfree = true;` in both system and Home Manager); the commented `allowUnfreePredicate` block in `nixos/configuration.nix` is not the active configuration.
- Desktop defaults are GNOME on X11 with VMware guest integration (`services.xserver.videoDrivers = [ "vmware" ];` and `virtualisation.vmware.guest.enable = true;`); keep that baseline unless the user asks to change it.
- SSH uses `~/.1password/agent.sock` and host-specific GitHub identities in `home-manager/ssh.nix`; GitHub SSH changes should stay aligned with those match blocks.
- Zsh and tmux are intentionally opinionated: Prezto modules live in `home-manager/zsh.nix`, and tmux uses backtick as the main prefix in `home-manager/tmux.nix`.
- `home-manager/nixvim.nix` mixes declarative Nixvim options with embedded Lua for keymaps and plugin setup; follow that pattern for editor changes instead of introducing ad-hoc Lua files.

## Integration notes
- Keep new flake inputs version-aligned with the existing `25.11` pins in `flake.nix`, especially when they depend on `nixpkgs`.
- `home-manager/home.nix` uses `systemd.user.startServices = "sd-switch"`; Home Manager reload behavior depends on that staying intact.
- Flakes only see tracked files, so new modules must be added to git before evaluation can import them.
- `nixos/hardware-configuration.nix` is generated machine state; only change it for real hardware or disk-layout updates.