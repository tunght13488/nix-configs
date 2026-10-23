# pi-box: run the Pi coding agent in a per-project rootless-Docker sandbox.
#
# Consumers: home-manager/home.nix imports this module. The `pi-box` wrapper is
# installed on PATH, and it builds the base image from the Dockerfile deployed
# to ~/.pi/sandbox/Dockerfile. Per-project images extend that base via an
# untracked Dockerfile.pi, with extra grants declared in pi-box.toml.
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
      yq-go
    ];
    # SC2016: the init templates are literals, their $(...) must not expand.
    excludeShellChecks = [ "SC2016" ];
    text = lib.replaceStrings [ "__PI_VERSION__" ] [ piVersion ]
      (builtins.readFile ./pi-box.sh);
  };
in
{
  home.packages = [ piBox ];

  # The wrapper builds this on demand; keep it alongside the Pi agent state.
  home.file.".pi/sandbox/Dockerfile".source = ./pi-sandbox.Dockerfile;

  # Housekeeping note for future readers: no system-level Docker changes are
  # needed here - nixos/configuration.nix already enables rootless Docker,
  # which maps container root to this user.
}
