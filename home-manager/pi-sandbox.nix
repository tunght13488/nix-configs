# pi-box: run the Pi coding agent in a per-project nono capability sandbox.
#
# Consumers: home-manager/home.nix imports this module. The `pi-box` wrapper is
# installed on PATH; it generates a small per-run overlay profile (workspace,
# worktree git directory, herdr socket, gh token route) and starts Pi under
# `nono run --profile <project|pi-box> --extends pi-box-overlay-<project>`.
#
# The shared base profile is deployed to ~/.config/nono/profiles/pi-box.json;
# project profiles extend it by name. Nono enforces the grant set with Landlock,
# so ungranted host paths are unreadable rather than merely unmounted.
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

  # Static part of the policy, shared by every project. Dynamic grants
  # (workspace, worktree git dir, herdr socket, token route) come from the
  # per-run overlay the wrapper generates; nono unions them.
  #
  # api.github.com is L7-filtered to read endpoints plus PR creation and the
  # Copilot OAuth exchange; the provider domains are plain CONNECT tunnels so
  # the chat APIs work unfiltered. The credentials entry is added by the
  # overlay only when a token file exists.
  baseProfile = pkgs.writeText "pi-box-base-profile.json" (builtins.toJSON {
    extends = "default";
    meta = {
      name = "pi-box";
      description = "Shared pi-box base profile; project profiles extend this by name.";
    };
    filesystem = {
      allow = [
        "${homeDir}/.pi/agent"
        "${homeDir}/.pi/sandbox/tmp"
        "${homeDir}/.local/state/nvim"
        "${homeDir}/.local/share/nvim"
        "${homeDir}/.config/github-copilot"
      ];
      read = [
        "/nix"
        "${homeDir}/.config/git"
        "${homeDir}/.config/gh"
        "${homeDir}/.config/nvim"
        "${homeDir}/.pi/sandbox/runtime"
      ];
    };
    network = {
      network_profile = "developer";
      allow_domain = [
        {
          domain = "api.github.com";
          endpoints = [
            { method = "GET"; path = "/user"; }
            { method = "GET"; path = "/repos/**"; }
            { method = "GET"; path = "/search/**"; }
            { method = "GET"; path = "/notifications"; }
            { method = "POST"; path = "/repos/*/pulls"; }
            { method = "POST"; path = "/copilot_internal/**"; }
            # shortcut: GraphQL is one endpoint, so path rules cannot tell a
            # read from a mutation. Drop this rule to hard-block `gh` writes
            # that go through it.
            { method = "POST"; path = "/graphql"; }
          ];
        }
        "*.githubcopilot.com"
        "proxy.business.githubcopilot.com"
        "opencode.ai"
        "api.opencode.ai"
        # pi-web-access: the built-in web search and reader providers.
        # Everything else stays blocked; arbitrary-URL reading goes through
        # r.jina.ai when the Jina reader fallback is enabled.
        "api.exa.ai"
        "mcp.exa.ai"
        "api.tavily.com"
        "api.search.brave.com"
        "google.serper.dev"
        "kagi.com"
        "jina.ai"
        "r.jina.ai"
        "s.jina.ai"
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
