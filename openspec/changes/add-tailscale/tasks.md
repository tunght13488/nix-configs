# Tasks

## 1. NixOS configuration

- [x] 1.1 Create `nixos/tailscale.nix` with `services.tailscale.enable = true` and `openFirewall = true`, plus a header comment documenting the one-time `sudo tailscale up --ssh` bootstrap; verify `make os-build` evaluates successfully
- [x] 1.2 Import `./tailscale.nix` from `nixos/configuration.nix`; verify `make os-build` still evaluates
- [x] 1.3 `git add nixos/tailscale.nix`; verify `git status` shows the new file staged (flake evaluation requires the file to be tracked)

## 2. Bootstrap (human, on the machine)

- [ ] 2.1 Run `make os`; verify the activation completes and `systemctl is-active tailscaled` reports `active`
- [ ] 2.2 Run `sudo tailscale up --ssh` and authenticate in the browser; verify the machine appears in the tailnet admin console and `tailscale status` shows the tailnet IP
- [ ] 2.3 Verify the firewall rule exists: `sudo nft list ruleset | grep 41641` shows an inbound accept on the tailscale port
- [ ] 2.4 If the tailscale login name is not `tung`, add a user-mapping ACL rule in the admin console; verify a tailnet SSH session lands in a `tung` shell

## 3. Phone access verification (human, on the iPhone)

- [ ] 3.1 Install the Tailscale app, sign in to the same tailnet, install moshi, and connect to `nixos-vmware` with empty credentials; verify a shell opens as `tung`
- [ ] 3.2 Run `herdr` in the phone shell; verify the mobile layout appears and the existing workspaces, panes, and agents are listed
- [ ] 3.3 From the VM, confirm no SSH is exposed off-tailnet: `systemctl status sshd` shows no such service and `tailscale status` lists the phone as a connected peer

## Workflow follow-up

- Sync the delta spec to the main spec and archive the change when implementation and phone verification are complete.
