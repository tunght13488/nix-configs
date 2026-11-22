# Proposal

## Why

The VM currently has no inbound remote access at all: sshd is disabled and there is no VPN. The user wants to reach the machine's herdr sessions and agent panes from an iPhone while away from the desk, without exposing SSH to the host network or managing SSH keys. Tailscale gives a private WireGuard mesh plus Tailscale SSH, which covers both with minimal configuration.

## What Changes

- Enable the NixOS `services.tailscale` module on `nixos-vmware` with `openFirewall = true` so direct tailnet connections work (UDP 41641) instead of falling back to slower DERP relays.
- Provide Tailscale SSH (port 22 on the tailnet only) as the remote shell path: no `services.openssh`, no SSH keys, ACL-driven auth. Enabled by a one-time manual `sudo tailscale up --ssh`; the flag persists in tailscaled state across rebuilds and reboots.
- Document the phone-side setup: Tailscale iOS app as the tunnel plus the moshi SSH client pointing at the machine's MagicDNS name, then `herdr` (which switches to its mobile layout automatically).
- Deliberately out of scope: remote access to the local dev sites (`*.vm.local` vhosts), exit-node or subnet-routing features, and declarative auth via agenix authkey.

## Capabilities

### New Capabilities

- `tailscale-remote-access`: tailnet connectivity for the machine and tailnet-only SSH access to its shell, herdr sessions, and agent panes.

### Modified Capabilities

<!-- none -->

## Impact

- `nixos/tailscale.nix` (new file) and its import in `nixos/configuration.nix`.
- `networking.firewall.allowedUDPPorts` gains 41641 via the module's `openFirewall` option.
- Tailnet admin console: machine registration and (only if the tailnet login name differs from `tung`) a user-mapping ACL rule for Tailscale SSH.
- No changes to nginx, dnsmasq, local-dev, herdr, or ngrok configuration.
