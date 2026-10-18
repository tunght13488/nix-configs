# pi coding agent — flake-provided binary (inputs.pi) running inside a
# bubblewrap jail (jail.nix, via the pi.nix home-manager module).
#
# The jail exposes the checked-out worktree plus a build/lint/test toolchain,
# and denies the user's credential surfaces: ~/.aws, ~/.ssh, the 1Password
# agent socket, ~/.npmrc, the token-bearing ~/.config/nix/nix.conf, and the
# herdr client socket are never mounted. herdr still reports pi state through
# its screen detection, driven by the host-visible HERDR_AGENT hint below.
#
# Host-side operations (never run inside the jail): make update, make home,
# make os. Available inside the jail: make home-build, make os-build, gh,
# openspec, and the project toolchains.
#
# See openspec/changes/migrate-pi-to-pi-nix-with-jail/ for the full design.
{ config
, pkgs
, ...
}:

let
  homeDir = config.home.homeDirectory;

  # Same INI-configured PHP wrappers the NixOS layer installs system-wide
  # (nixos/configuration.nix), rebuilt from the shared php-config module.
  php81 = config.phpConfig._lib.versions.php81;
  php82 = config.phpConfig._lib.versions.php82;
  php83 = config.phpConfig._lib.versions.php83;

  # Repos the agent works in. All use the same git-worktree layout: a bare
  # repository plus one directory per worktree. The roots are mounted read-only
  # so sibling worktrees stay readable for reference, while each .bare is
  # writable because every git command run from a worktree (status, commit)
  # needs it.
  repos = [
    "${homeDir}/code/nix-configs"
    "${homeDir}/code/netsuite-middleware"
    "${homeDir}/code/fc-es-starter-pack"
    "${homeDir}/code/fc-omx"
  ];

  # Minimal gitconfig for inside the jail. There is no ~/.config/git/config
  # in there (the jail home is a tmpfs) and pushes must go over https, because
  # the 1Password SSH agent is deliberately unavailable. Identity and the two
  # defaults are read from the real git settings so they cannot drift.
  jailedGitConfig = ''
    [user]
        name = ${config.programs.git.settings.user.name}
        email = ${config.programs.git.settings.user.email}
    [url "https://github.com/"]
        insteadOf = git@github.me:
    [credential "https://github.com"]
        helper = !gh auth git-credential
    [push]
        default = ${config.programs.git.settings.push.default}
    [init]
        defaultBranch = ${config.programs.git.settings.init.defaultBranch}
  '';
in
{
  programs.pi.coding-agent = {
    enable = true;

    # The settings/rules/skills/extensions options are deliberately unused:
    #   - ~/.pi/agent/settings.json stays hand-managed (declaring settings
    #     would jq-merge the declared keys on every invocation)
    #   - ~/.pi/agent/AGENTS.md stays owned by ./ai.nix
    #   - ~/.pi/agent/skills/herdr/SKILL.md stays owned by ./herdr.nix
    #   - npm packages and extensions/*.ts load natively from the agent dir
    jail = {
      enable = true;

      # This replaces pi.nix's default permission list, so `network` and
      # `mount-cwd` are re-included. Order matters: bwrap applies binds in
      # order and later mounts win, so the read-only repo roots precede the
      # writable .bare binds and mount-cwd.
      permissions =
        combinators:
        let
          c = combinators;
        in
        # --- checked-out code: read-only roots, writable worktree and bare repo
        (map c.readonly repos)
        ++ (map (repo: c.rw-bind "${repo}/.bare" "${repo}/.bare") repos)
        ++ [
          c.network # model APIs, extension package downloads
          c.mount-cwd # the worktree the agent was started in

          # --- nix: evaluation and builds happen through the daemon, which
          # sandboxes its own builds; only the store and the socket are needed
          (c.readonly "/nix/store")
          (c.try-readwrite "/nix/var/nix/daemon-socket")
          # The system config carries substituters but no access-tokens. The
          # user-level ~/.config/nix/nix.conf (which does carry the GitHub
          # access token) is deliberately not mounted.
          (c.try-readonly "/etc/nix")
          (c.try-readwrite "${homeDir}/.cache/nix")

          # --- gh: authenticated through the existing config, read-only
          (c.try-readonly "${homeDir}/.config/gh")

          # --- openspec CLI from ~/.npm-global. bin/ is bound as a directory
          # so its symlink into lib/node_modules still resolves inside the jail;
          # ~/.npmrc and the other global CLIs' caches stay out.
          (c.try-ro-bind "${homeDir}/.npm-global/bin" "${homeDir}/.npm-global/bin")
          (c.try-ro-bind "${homeDir}/.npm-global/lib/node_modules" "${homeDir}/.npm-global/lib/node_modules")

          # --- global agent skills (find-skills)
          (c.try-readonly "${homeDir}/.agents")

          # --- project toolchain dependency caches. The jail home is a tmpfs,
          # so Maven, npm, Yarn, and Composer would re-download everything on
          # every session; these bind the real caches. The host-side mkdir
          # guarantees the read-write binds below always have a target.
          (c.add-runtime ''
            mkdir -p "$HOME/.m2" "$HOME/.npm" "$HOME/.cache/yarn" "$HOME/.cache/composer"
          '')
          (c.readwrite "${homeDir}/.m2")
          (c.readwrite "${homeDir}/.npm")
          (c.readwrite "${homeDir}/.cache/yarn")
          (c.readwrite "${homeDir}/.cache/composer")

          # Maven reads JAVA_HOME before falling back to its own JDK; the
          # fc-es-starter-pack dev shell sets the same value for Java 8.
          (c.set-env "JAVA_HOME" "${pkgs.jdk8}")

          (c.write-text "${homeDir}/.gitconfig" jailedGitConfig)

          (c.add-pkg-deps [
            # repository build / test tooling
            pkgs.nix
            pkgs.direnv
            pkgs.gnumake
            pkgs.nixpkgs-fmt
            pkgs.gh

            # PHP + Composer, versioned exactly like the system profile exposes
            # them (php81/php82/php83, composer81/82/83) plus the 8.3-based
            # defaults the user-level wrappers point at
            php81.versionedPkg
            php81.composerVersionedPkg
            php82.versionedPkg
            php82.composerVersionedPkg
            php83.versionedPkg
            php83.composerVersionedPkg
            php83.defaultPkg
            php83.composerPkg

            # project toolchains, matching the dev shells in flake.nix:
            # netsuite-middleware (PHP, above), fc-es-starter-pack (Java 8,
            # Maven, Node, jq), fc-omx (Node 22, Yarn). nodejs_22 is listed
            # before nodejs so bare `node` resolves to 22, which fc-omx
            # requires (engines.node = 22.*).
            pkgs.nodejs_22
            pkgs.yarn
            pkgs.jdk8
            pkgs.maven363
            pkgs.nodejs
            pkgs.jq
          ])

          # Runs outside the jail, before bwrap starts, so the variable lands in
          # the host-visible process environment that herdr inspects. Without
          # it herdr would see the wrapper instead of pi and report no state.
          (c.add-runtime ''
            export HERDR_AGENT=pi
          '')

          # Belt and braces for the same hint: bwrap runs --clearenv, so if herdr
          # ends up inspecting the jailed process (its child-process-group
          # fallback mode) rather than the host-side wrapper, only the in-jail
          # value is visible. This is the one HERDR_* variable that is set: the
          # socket variables stay out, so pi's herdr reporting extension remains
          # inert and herdr reports state from screen detection instead.
          (c.set-env "HERDR_AGENT" "pi")
        ];
    };
  };
}
