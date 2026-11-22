# Tasks

## 1. NixOS configuration

- [x] 1.1 Create `nixos/tailscale.nix` with `services.tailscale.enable = true` and `openFirewall = true`, plus a header comment documenting the one-time `sudo tailscale up --ssh` bootstrap; verify `make os-build` evaluates successfully
- [x] 1.2 Import `./tailscale.nix` from `nixos/configuration.nix`; verify `make os-build` still evaluates
- [x] 1.3 `git add nixos/tailscale.nix`; verify `git status` shows the new file staged (flake evaluation requires the file to be tracked)

## 2. Bootstrap (human, on the machine)

- [x] 2.1 Run `make os`; verify the activation completes and `systemctl is-active tailscaled` reports `active`
- [x] 2.2 Run `sudo tailscale up --ssh` and authenticate in the browser; verify the machine appears in the tailnet admin console and `tailscale status` shows the tailnet IP
- [x] 2.3 Verify the firewall rule exists: `sudo iptables -L nixos-fw -nv | grep 41641` shows an inbound accept on the tailscale port
- [x] 2.4 If the tailscale login name is not `tung`, add a user-mapping ACL rule in the admin console; verify a tailnet SSH session lands in a `tung` shell

## 3. Phone access verification (human, on the iPhone)

- [x] 3.1 Install the Tailscale app, sign in to the same tailnet, connect with an SSH client to `nixos-vmware`; verify a shell opens as `tung`
- [x] 3.3 From the VM, confirm no SSH is exposed off-tailnet: `systemctl status sshd` shows no such service and `tailscale status` lists the phone as a connected peer

## Deferred

- Herdr on the phone (`herdr` over the tailnet SSH session) is out of scope for this change. The Herdr iOS app needs `herdr-core`, a separate runtime from the Herdr TUI this repo installs; that is a separate change.

## Workflow follow-up

- Sync the delta spec to the main spec and archive the change when implementation and phone verification are complete.
