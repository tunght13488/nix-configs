# tailscale-remote-access Specification

## Purpose
Connect the machine to a private Tailscale mesh and provide tailnet-only SSH
access to its shell from a phone, without exposing SSH to the host network.

## Requirements

### Requirement: Tailscaled service runs on the machine
The system SHALL run the tailscaled daemon as an enabled systemd service via
the NixOS `services.tailscale` module, configured in a dedicated
`nixos/tailscale.nix` module imported from `nixos/configuration.nix`.

#### Scenario: Service enabled after activation
- **WHEN** the NixOS configuration is activated with the tailscale module enabled
- **THEN** `tailscaled.service` is enabled and running

### Requirement: Direct tailnet connections are permitted
The firewall SHALL accept inbound UDP on the tailscale port (41641) so peers
can establish direct WireGuard connections instead of relaying through DERP.

#### Scenario: Inbound UDP 41641 allowed
- **WHEN** the NixOS configuration is activated
- **THEN** the firewall permits inbound UDP 41641 on the tailscale interface

#### Scenario: Connection survives without relay
- **WHEN** a tailnet peer initiates a connection to this machine from a
  network that permits NAT traversal
- **THEN** the connection is established directly between peers rather than
  via a DERP relay

### Requirement: SSH is available on the tailnet only
The machine SHALL provide Tailscale SSH on port 22 for tailnet peers,
authenticated by tailnet identity. The system SHALL NOT run an OpenSSH
server, so no SSH listener exists outside the tailnet.

#### Scenario: Tailnet peer connects without SSH keys
- **WHEN** an authorized tailnet peer runs `ssh tung@<machine-tailnet-name>`
  with no SSH key or password configured
- **THEN** the connection is authenticated using the peer's tailnet identity
  and a shell opens

#### Scenario: SSH is not exposed to the host network
- **WHEN** a device on the VMware NAT network attempts to connect to port 22
  on the machine
- **THEN** the connection is refused because no SSH daemon listens outside
  the tailnet

### Requirement: Registration and SSH flag survive rebuilds and reboots
A one-time interactive `sudo tailscale up --ssh` SHALL be sufficient to join
the tailnet with SSH enabled. The registration and the `--ssh` preference
SHALL persist in tailscaled state across NixOS rebuilds and reboots, without
an agenix-managed authkey.

#### Scenario: Reboot keeps the machine joined
- **WHEN** the machine is rebooted after a successful `tailscale up --ssh`
- **THEN** the machine reconnects to the tailnet automatically with SSH
  still enabled

#### Scenario: NixOS rebuild keeps the machine joined
- **WHEN** a `nixos-rebuild switch` is performed after the one-time `tailscale up`
- **THEN** the machine remains joined to the tailnet and no new
  authentication is required

### Requirement: Remote shell lands as the tung user
The tailnet identity used from the phone SHALL be mapped to the local user
`tung`, so remote sessions run as the same user as the desktop.

#### Scenario: Mismatched tailnet login is mapped
- **WHEN** the tailnet login name differs from `tung`
- **THEN** a user-mapping rule in the tailnet ACL maps the login to the
  local `tung` user, and `ssh` lands in a `tung` shell

### Requirement: Local dev stack is unaffected
The change SHALL NOT modify nginx, dnsmasq, or the `*.vm.local` hostname
resolution. Browsing dev sites on the host SHALL behave exactly as before.

#### Scenario: Dev sites still resolve on the host
- **WHEN** the change is applied
- **THEN** `*.vm.local` names still resolve to 127.0.0.1 on the host and all
  existing vhosts remain reachable locally
