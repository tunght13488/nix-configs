# nixos/tailscale.nix — Tailscale mesh + tailnet-only SSH
#
# Joins the machine to a Tailscale tailnet so Herdr Mobile can reach
# herdr-core over SSH without exposing SSH to the VMware NAT network.
#
# openFirewall opens inbound UDP 41641 so peers connect directly instead of
# relaying through DERP. No OpenSSH server runs: `tailscale up --ssh` serves
# SSH on the tailnet only, authenticated by tailnet identity (ACL-driven).
#
# Bootstrap is a one-time manual step, not declarative (no agenix authkey):
#   sudo tailscale up --ssh
# The registration and the --ssh flag persist in /var/lib/tailscale across
# rebuilds and reboots; rerun only after `tailscale logout` or a fresh install.
#
# If the tailnet login name is not `tung`, add a user-mapping rule in the
# tailnet ACL so SSH lands in the local user's shell.
{ ... }:
{
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };
}
