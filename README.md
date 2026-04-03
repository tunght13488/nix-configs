# nix-configs

Flake-based personal NixOS configuration for the `nixos-vmware` machine.

## What this repo manages

- System configuration in `nixos/configuration.nix`
- User configuration in `home-manager/home.nix`
- Flake entrypoints in `flake.nix`

This repo keeps NixOS and Home Manager separate. The flake exposes:

- `nixosConfigurations.nixos-vmware`
- `homeConfigurations."tung@nixos-vmware"`

## Layout

```text
.
├── flake.nix
├── home-manager/
│   └── home.nix
└── nixos/
    ├── configuration.nix
    └── hardware-configuration.nix
```

- `nixos/configuration.nix` contains host-level settings such as networking, desktop, users, system packages, and Nix configuration.
- `home-manager/home.nix` contains per-user settings and currently stays intentionally minimal.
- `nixos/hardware-configuration.nix` is generated hardware state and should only change for hardware-related updates.

## Current defaults

- Hostname: `nixos-vmware`
- User: `tung`
- Desktop: GNOME on X11
- Virtualization support: VMware guest tools enabled
- Shell: `zsh`
- Browser policy example: Firefox telemetry disabled through enterprise policies
- Unfree packages allowed, with a targeted `allowUnfreePredicate` for packages such as `vscode`, `google-chrome`, and `1password-gui`

## Common workflows

Typical edit cycle from the repo root:

```zsh
nix flake show --no-write-lock-file
sudo nixos-rebuild switch --flake ".#nixos-vmware"
home-manager switch --flake ".#tung@nixos-vmware"
```

Use the full system rebuild when you change `nixos/configuration.nix`; use the Home Manager command when you change only `home-manager/home.nix`.

Validate the flake without changing `flake.lock`:

```zsh
nix flake show --no-write-lock-file
```

Rebuild the system from the repo root:

```zsh
sudo nixos-rebuild switch --flake ".#nixos-vmware"
```

Apply only the Home Manager profile:

```zsh
home-manager switch --flake ".#tung@nixos-vmware"
```

If `home-manager` is not installed:

```zsh
nix shell nixpkgs#home-manager --command home-manager switch --flake ."#tung@nixos-vmware"
```

Update pinned inputs intentionally:

```zsh
nix flake update
```

Format a Nix file after editing it:

```zsh
nixfmt nixos/configuration.nix
```

Replace the path with the file you changed.

## Where to make common changes

- Add system packages, desktop services, users, or host-level options in `nixos/configuration.nix`
- Add per-user packages or program settings in `home-manager/home.nix`
- Add new flake inputs or outputs in `flake.nix`
- Avoid editing `nixos/hardware-configuration.nix` unless the change is actually hardware-driven

Examples from the current setup:

- GNOME, GDM, and VMware guest integration are configured in `nixos/configuration.nix`
- Git is enabled in both the system config and Home Manager config
- Firefox policy settings are managed at the NixOS layer via `programs.firefox.policies`

## Notes for future changes

- Keep system-level changes in `nixos/configuration.nix` and user-level changes in `home-manager/home.nix`.
- Preserve the minimal inline structure unless there is a clear reason to split into more modules.
- `flake.nix` passes `inputs` into both modules, and `nixos/configuration.nix` derives `nix.registry` and `nix.nixPath` from those flake inputs.
- Flakes only see tracked files, so newly added modules must be added to git before evaluation can find them.
