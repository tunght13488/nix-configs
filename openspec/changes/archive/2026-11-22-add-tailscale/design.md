# Design

## Context

See proposal.md for motivation. Relevant current state:

- `nixos/configuration.nix` imports per-service modules (`nginx.nix`,
  `litellm.nix`, `mysql.nix`, ...); machine-specific services live in
  `nixos/` as separate files.
- The NixOS firewall is enabled (the module default) and already allows
  TCP 80/443 and 1024-49151. UDP 41641 (the tailscale port) is blocked.
- sshd is disabled (commented out in `configuration.nix`); the only SSH
  material is the agenix identity key under `~/.ssh/`.
- herdr runs a persistent server on the VM. Reaching it from a phone is a
  follow-up concern, not part of this change: the Herdr iOS app requires
  `herdr-core`, a separate runtime from the Herdr TUI, and is not packaged
  in nixpkgs 26.05.
- The firewall uses the iptables backend (`firewall.service` depends on
  iptables, no `/etc/nftables.conf`), so verification uses `iptables`, not
  `nft`.
- Pinned nixpkgs (26.05) `services.tailscale` module options verified:
  `enable`, `openFirewall` (adds `networking.firewall.allowedUDPPorts
  [ 41641 ]`), `authKeyFile`, `extraUpFlags` (applied only when
  `authKeyFile` is set).

## Goals / Non-Goals

**Goals:**

- Tailnet-only SSH into the VM from an iPhone, landing in the `tung`
  shell.
- Direct peer connections (no forced DERP relay).

**Non-Goals:**

- Herdr access from the phone (deferred; needs `herdr-core`, out of scope).
- Remote access to `*.vm.local` dev sites (no dnsmasq/nginx changes).
- Exit node, subnet routing, or ACL policy redesign beyond a possible
  user-mapping rule.
- Declarative re-registration (agenix authkey).
- Any phone-side automation; phone setup is manual and outside the repo.

## Decisions

**D1: Tailscale SSH instead of an OpenSSH server.**
The machine has no sshd today and the goal is access from one phone.
Tailscale SSH needs no keys, no sshd config, exposes port 22 only on the
tailnet, and authenticates by tailnet identity (ACL-controlled). The
admin-console web SSH works in the phone browser as a fallback client, and
any SSH client works over the Tailscale tunnel (Termius was used to verify).
Alternative considered: enable `services.openssh` with key auth and open
port 22. Rejected: more moving parts, a listener reachable from the
VMware NAT network, and no identity-based auth. Trade-off: mosh cannot be
used with Tailscale SSH (mosh needs OpenSSH); plain SSH is used instead.

**D2: `openFirewall = true` on the tailscale module.**
With the firewall enabled, inbound UDP 41641 is blocked by default and
the machine would fall back to DERP relays for all traffic (usable but
slower). One option opens the port for direct WireGuard connections.
Alternative considered: leave the firewall closed and accept DERP.
Rejected: negligible exposure (single UDP port, wireguard handshake only)
vs. noticeably better latency for interactive SSH sessions.

**D3: One-time manual `tailscale up --ssh` over a declarative authkey.**
Registration and the `--ssh` preference live in tailscaled state
(`/var/lib/tailscale`) and persist across rebuilds and reboots. The
module's `extraUpFlags` is only applied by the autoconnect service when
`authKeyFile` is set, so a declarative setup would need an agenix-managed
authkey, an `age.secrets` entry, and a second `tailscaled-autoconnect`
service - machinery that earns nothing on a personal machine that is
interactive during `make os` anyway. Alternative considered:
`authKeyFile` + agenix. Rejected as overkill; can be adopted later
without changing this design's other decisions.

**D4: New `nixos/tailscale.nix` module file, imported from
`configuration.nix`.**
Matches the existing per-service convention (`litellm.nix`, `nginx.nix`)
and keeps `configuration.nix` a manifest of imports. The module contains
only `services.tailscale.enable = true` and `openFirewall = true`; a
header comment documents the one-time `tailscale up --ssh` bootstrap.

**D5: No DNS or web-stack changes.**
The phone reaches SSH via the machine's MagicDNS name (`nixos-vmware`).
Dev-site browsing from the phone is out of scope, so dnsmasq's
`*.vm.local` -> 127.0.0.1 answers and the nginx vhosts stay untouched.

## Risks / Trade-offs

- [Setup interrupted before `tailscale up` completes] -> The machine is
  simply not reachable; the command is idempotent, rerun it.
- [NAT traversal fails between phone and VM] -> Tailscale falls back to
  DERP relays; sessions work with higher latency. Acceptable for a
  single-phone setup.
- [Tailnet ACL switched to "check" mode] -> the SSH client cannot complete
  the browser-based auth-URL flow and login fails. Keep the ACL in accept
  mode (default).
- [Tailnet login name differs from `tung`] -> First SSH fails with a user
  lookup error until an ACL user-mapping rule (`"users": ["tung"]`) is
  added in the admin console. Documented as a conditional setup step.
- [sshd is enabled later] -> port 22 on the tailnet would conflict with
  tailscaled. Future sshd setups must pick a different port or drop
  Tailscale SSH.
- [Firewall change] -> opens one UDP port; the tailscaled service only
  accepts WireGuard handshakes there. No new TCP exposure.

## Migration Plan

1. Human runs `make os` to apply the new module (build is verified with
   `make os-build` by the agent first).
2. Human runs `sudo tailscale up --ssh`, authenticates in the browser,
   and confirms the machine appears in the tailnet admin console.
3. Human installs the Tailscale app on the iPhone, signs in to the same
   tailnet, and connects an SSH client to `nixos-vmware`. If login fails
   with a user error, add the ACL user-mapping rule, then retry.
4. Verify: the session opens a shell as `tung`; `sudo iptables -L nixos-fw
   -nv | grep 41641` shows the ACCEPT rule.

Rollback: remove the import and the `nixos/tailscale.nix` file, rebuild.
Tailscale state remains on disk but the daemon no longer starts;
`sudo tailscale down` removes the machine from the tailnet.

## Open Questions

None.
