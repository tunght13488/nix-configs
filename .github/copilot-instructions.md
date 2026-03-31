# Copilot instructions for `nix-configs`

## Big picture
- This repo started from `github:misterio77/nix-starter-config#minimal` via `nix flake init`. It keeps that template's core shape: a single flake, one `nixos/` tree, and one `home-manager/` tree.
- This repo is a flake-based personal NixOS setup for the `nixos-vmware` host. `flake.nix` is the entrypoint and exposes both `nixosConfigurations.nixos-vmware` and `homeConfigurations."tung@nixos-vmware"`.
- System-level configuration lives in `nixos/configuration.nix`; user-level configuration lives in `home-manager/home.nix`. Keep that split: OS services, users, desktop, and system packages belong in the NixOS module; per-user tools and dotfile-style settings belong in Home Manager.
- The repo still uses the template's standalone Home Manager design, not Home Manager as a NixOS module. Preserve the separate `homeConfigurations` output and prefer `home-manager switch` for user-level changes unless the user asks to merge them.
- `nixos/configuration.nix` currently imports only `./hardware-configuration.nix`. The structure is intentionally simple and inline rather than heavily modularized.
- The workspace also includes `/etc/nixos`, which is a separate live-machine config. Its `configuration.nix` imports `./home-manager.nix`, and `home-manager.nix` pulls Home Manager via `builtins.fetchTarball` instead of flakes.

## Editing conventions
- Prefer changing the flake-backed repo under `nix-configs/` first. Only update `/etc/nixos/*` when the task is explicitly about the live system config or requires keeping the non-flake copy in sync.
- Treat this as a customized copy of the template's `minimal` variant, not `standard`: do not add `pkgs/`, `overlays/`, or `modules/` boilerplate unless the user explicitly wants to evolve the repo beyond the minimal layout.
- Preserve existing host/user identifiers unless the user asks otherwise: hostname `nixos-vmware`, user `tung`, home path `/home/tung`.
- Some comments and scaffolding markers (`FIXME`, `TODO`) are inherited from the starter template. They are guidance, not evidence that the repo is incomplete or needs broad cleanup.
- Keep unfree-package handling aligned with existing patterns: broad `allowUnfree = true;` plus a targeted `allowUnfreePredicate` for packages such as `vscode`, `google-chrome`, and `1password-gui`.
- Follow the current style: inline attribute sets, short comment blocks, and package lists in `environment.systemPackages = with pkgs; [ ... ];`.
- Do not "clean up" the generated `hardware-configuration.nix` files unless the task specifically requires hardware changes.

## Typical workflows
- Rebuild the flake-based system from the repo root:
  `sudo nixos-rebuild switch --flake .#nixos-vmware`
- Apply only the user profile from the repo root:
  `home-manager switch --flake .#tung@nixos-vmware`
- If `home-manager` is not installed in the environment, the template's fallback still applies:
  `nix shell nixpkgs#home-manager --command home-manager switch --flake .#tung@nixos-vmware`
- Validate the flake parses before larger edits without mutating `flake.lock`:
  `nix flake show --no-write-lock-file`
- Update pinned dependencies intentionally with `nix flake update`; the flake uses the commits recorded in `flake.lock`, not just the branch names in `flake.nix`.
- If you must work against the live `/etc/nixos` copy, use the classic rebuild path instead of the flake command:
  `sudo nixos-rebuild switch -I nixos-config=/etc/nixos/configuration.nix`

## Repo-specific patterns
- Firefox is configured through enterprise policies (`programs.firefox.policies.DisableTelemetry = true;`) rather than wrapper scripts or extra prefs files.
- Desktop defaults are GNOME on X11 with VMware guest support (`services.xserver.videoDrivers = [ "vmware" ];` and `virtualisation.vmware.guest.enable = true;`). New desktop changes should fit that baseline unless the user asks to change display stack.
- User shells are explicitly set to `pkgs.zsh`, and both system and home configs enable Git/Zsh-related programs. Keep shell changes consistent across user and program declarations.
- The Home Manager module is intentionally minimal: it sets identity, enables `programs.home-manager` and `programs.git`, and uses `systemd.user.startServices = "sd-switch"` for smooth reloads.

## Integration points
- `flake.nix` wires `home-manager.inputs.nixpkgs.follows = "nixpkgs"`; when adding new flake inputs, keep versions compatible with the pinned `nixos-25.11` / `release-25.11` channels.
- The NixOS module derives `nix.registry` and `nix.nixPath` from flake inputs. Avoid changes that re-enable channels or a global registry unless the user explicitly wants that behavior.
- Nix flakes only see tracked files. If a newly added module or file seems invisible during evaluation, ensure it is not ignored and has been added to git.
- Secrets and machine-specific state are not abstracted into reusable modules here; avoid introducing secret values or replacing existing hashed passwords unless requested.
- The upstream starter repo is useful for background context, but its README explicitly notes it is a bit out of date. Prefer the current local files and official Nix/Home Manager docs over blindly reintroducing template-era patterns.