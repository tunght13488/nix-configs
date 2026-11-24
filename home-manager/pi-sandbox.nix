# pi-box: run the Pi coding agent in a per-project nono capability sandbox.
#
# Consumers: home-manager/home.nix imports this module. The `pi-box` wrapper is
# installed on PATH; it generates a small per-run overlay profile (workspace,
# worktree git directory, legacy TUI socket, gh token route) and starts Pi under
# `nono run --profile <project|pi-box> --extends pi-box-overlay-<project>`.
#
# The shared base profile is deployed to ~/.config/nono/profiles/pi-box.json as a
# child of the registry Pi profile (`nono pull nolabs-ai/pi` installs it); project
# profiles extend pi-box by name. Nono enforces the grant set with Landlock, so
# ungranted host paths are unreadable rather than merely unmounted.
#
# The stack templates the wrapper scaffolds from are deployed as a directory of
# store symlinks under ~/.pi/sandbox/templates; the repository copy in
# ./pi-box-templates stays the source of truth.
{ pkgs
, lib
, config
, ...
}:

let
  homeDir = config.home.homeDirectory;

  # Static part of the policy, shared by every project. It inherits the registry
  # Pi profile's filesystem grants and runtime groups (including ~/.pi and
  # ~/.cache read-write) and its default-allow network policy, then adds the
  # host-specific grants pi-box needs. Dynamic grants (workspace, worktree git
  # dir, legacy TUI socket, token route) come from the per-run overlay; the Core
  # socket directory is static because its path is fixed on this host.
  #
  # The GitHub token route lives in the overlay, which activates it only when the
  # token file exists. Its endpoint rules restrict that brokered credential, not
  # general outbound traffic.
  baseProfile = pkgs.writeText "pi-box-base-profile.json" (builtins.toJSON {
    extends = "nolabs-ai/pi";
    meta = {
      name = "pi-box";
      description = "Shared pi-box base profile; project profiles extend this by name.";
    };
    filesystem = {
      allow = [
        "${homeDir}/.pi/agent"
        "${homeDir}/.cache"
        "/tmp"
        "${homeDir}/.local/state/nvim"
        "${homeDir}/.local/share/nvim"
        "${homeDir}/.config/github-copilot"
      ];
      unix_socket_dir = [ "/run/user/1000/herdr-core" ];
      read = [
        "/nix"
        "${homeDir}/.config/git"
        "${homeDir}/.config/gh"
        "${homeDir}/.config/nvim"
        "${homeDir}/.pi/sandbox/runtime"
        # The host OpenSpec CLI is an npm global install; grant its bin directory
        # and package read-only so `openspec` works inside the sandbox.
        "${homeDir}/.npm-global/bin"
        "${homeDir}/.npm-global/lib/node_modules/@fission-ai/openspec"
      ];
    };
    environment = {
      deny_vars = [ "AWS_*" "AZURE_*" "GOOGLE_APPLICATION_CREDENTIALS" "GH_TOKEN" ];
    };
  });

  piBox = pkgs.writeShellApplication {
    name = "pi-box";
    runtimeInputs = with pkgs; [
      coreutils
      git
      gnugrep
      gnused
      python3
      # Nono's own runtime helpers (socat bridges the proxy, bubblewrap backs
      # the Linux sandbox). They must be on pi-box's PATH because nono is
      # deliberately unwrapped - see pkgs/nono.nix.
      bubblewrap
      socat
      nono
    ];
    text = builtins.readFile ./pi-box.sh;
  };
in
{
  home.packages = [
    piBox
    pkgs.nono
  ];

  # The shared base profile projects extend by name. `pi-box` deploys the
  # per-run overlays next to it; that directory is read by nono, not managed
  # by home-manager.
  home.file.".config/nono/profiles/pi-box.json".source = baseProfile;

  # `pi-box init [template]` copies from here. The sources must be tracked in
  # git (force-added, since the global gitignore ignores the scaffold names)
  # or the flake would not see them.
  home.file.".pi/sandbox/templates" = {
    source = ./pi-box-templates;
    recursive = true;
  };

  # Housekeeping note for future readers: no system-level changes are needed
  # here. Nono needs Linux 5.13+ (Landlock), which this host has, and runs
  # unprivileged as the invoking user - rootless Docker is no longer involved.
}
