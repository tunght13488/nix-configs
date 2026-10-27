# pi-box: run the Pi coding agent in a per-project rootless-Docker sandbox.
#
# Consumers: home-manager/home.nix imports this module. The `pi-box` wrapper is
# installed on PATH, and it builds the base image from the Dockerfile deployed
# to ~/.pi/sandbox/Dockerfile. Per-project images extend that base via an
# untracked Dockerfile.pi, with extra grants declared in pi-box.toml.
#
# The stack templates the wrapper scaffolds from are deployed as a directory of
# store symlinks under ~/.pi/sandbox/templates; the repository copy in
# ./pi-box-templates stays the source of truth.
{ pkgs
, lib
, ...
}:

let
  # Pinned to the host Pi release; rebuild the base image after upgrading Pi.
  piVersion = "1.4.0";

  piBox = pkgs.writeShellApplication {
    name = "pi-box";
    runtimeInputs = with pkgs; [
      coreutils
      git
      gnugrep
      gnused
      iproute2
      python3
      yq-go
    ];
    text = lib.replaceStrings [ "__PI_VERSION__" ] [ piVersion ]
      (builtins.readFile ./pi-box.sh);
  };
in
{
  home.packages = [ piBox ];

  # The wrapper builds this on demand; keep it alongside the Pi agent state.
  home.file.".pi/sandbox/Dockerfile".source = ./pi-sandbox.Dockerfile;

  # Herdr state reporting relay: the wrapper starts it per run inside a herdr
  # pane and publishes only its socket to the container, never herdr's own.
  home.file.".pi/sandbox/pi-herdr-relay.py".source = ./pi-herdr-relay.py;

  # `pi-box init [template]` copies from here. The sources must be tracked in
  # git (force-added, since the global gitignore ignores the scaffold names)
  # or the flake would not see them.
  home.file.".pi/sandbox/templates" = {
    source = ./pi-box-templates;
    recursive = true;
  };

  # Housekeeping note for future readers: no system-level Docker changes are
  # needed here - nixos/configuration.nix already enables rootless Docker,
  # which maps container root to this user.
}
