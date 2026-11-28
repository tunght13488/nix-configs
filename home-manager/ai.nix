{ pkgs
, ...
}:

let
  global_instructions = ''
    ## Conversational Style

    - Keep answers short and concise
    - No emojis in commits, issues, PR comments, or code
    - No fluff or cheerful filler text (e.g., "Thanks @user" not "Thanks so much @user!")
    - Technical prose only, be direct
    - When the user asks a question, answer it first before making edits or running implementation commands.
    - When responding to user feedback or an analysis, explicitly say whether you agree or disagree before saying what you changed.

    ## Approach

    - Think before acting. Read existing files before writing code.
    - Be concise in output but thorough in reasoning.
    - Prefer editing over rewriting whole files.
    - Do not re-read files you have already read unless the file may have changed.
    - Test your code before declaring done.
    - No sycophantic openers or closing fluff.
    - Keep solutions simple and direct.
    - User instructions always override this file.

    ## Shell Commands

    - Always pass an explicit short `timeout` to bash tool calls: default 60 seconds.
    - Pass a larger `timeout` only for known-long operations (builds, downloads) and state the expected duration.

    ## Shell Environment

    - Default shell is **zsh** with Prezto, not bash
    - Prefer `bat` over `cat`
    - Prefer `rg` over `grep`
    - Prefer `fd` over `find`

    ## PHP projects

    - There are multiple PHP projects with different supported PHP versions. Always check the `composer.json` file for the required PHP version before running any commands.
    - Do not rely on the default `php` & `composer` binary for project commands. Use versioned binaries instead: `php82`, `php83`, `composer82`, `composer83`
    - Tests may rely on a test database. In such case, do not run tests in parallel

    ## Pull request

    - Use `gh` CLI to interact with GitHub PRs
    - Follow the PR template in `.github/PULL_REQUEST_TEMPLATE.md`
      - If any sections don't apply, remove them instead of leaving placeholders.
      - Should have a clear, concise problem statement
      - Describe the approach and reasoning, not just the final code changes

    ## Guardrails

    - Do not make changes outside of the current working directory unless explicitly instructed by the user. If you need to make changes outside the current working directory, ask for confirmation first.
  '';
in

{
  home.packages = with pkgs; [
    github-copilot-cli
    # Desktop app (official upstream AppImage); see pkgs/github-copilot-app.nix.
    github-copilot-app
    # Orca IDE for parallel agents (official upstream AppImage); see pkgs/orca.nix.
    orca-app
  ];

  programs.claude-code.enable = false;
  programs.claude-code.context = global_instructions;

  programs.opencode.enable = false;
  programs.opencode.package = pkgs.unstable.opencode;
  programs.opencode.context = global_instructions;
  programs.opencode.settings.share = "disabled";
  programs.opencode.settings.instructions = [ "AGENTS.local.md" ];
  programs.opencode.settings.experimental.disable_paste_summary = false;

  home = {
    # Declaratively configure ~/.pi/agent/AGENTS.md
    file = {
      ".pi/agent/AGENTS.md".text = global_instructions;
    };
  };

  # Headless Orca server for Remote Orca Server clients, no desktop window
  # required (see openspec/changes/run-orca-server-as-service). `--supervise`
  # is Orca's own restart policy for service managers: it retries with growing
  # delays and exits 0 once it gives up, so systemd owns boot only and does not
  # fight the supervisor. `--no-pairing` keeps pairing links out of the journal;
  # pair from a foreground `orca serve` while this unit is stopped.
  # Lingering (nixos/configuration.nix) keeps the user manager, and the server,
  # running without a login.
  systemd.user.services.orca-server = {
    Unit = {
      Description = "Orca headless server";
      Documentation = [ "https://orca.dev/docs/remote-servers" ];
    };
    Service = {
      ExecStart = "${pkgs.orca-app}/bin/orca-ide serve --supervise --no-pairing --port 6768";
      # Agent CLIs the server launches come from the user and system profiles.
      Environment = [
        "PATH=%h/.nix-profile/bin:/run/current-system/sw/bin:/usr/bin:/bin"
      ];
    };
    Install.WantedBy = [ "default.target" ];
  };
}
