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

    ## Shell Environment

    - Default shell is **zsh** with Prezto, not bash
    - use `bat` instead of `cat`
    - use `fd` instead of `find`
    - use `rg` instead of `grep`
    - use `eza` instead of `ls`

    ## PHP projects

    - There are multiple PHP projects with different supported PHP versions. Always check the `composer.json` file for the required PHP version before running any commands.
    - Do not rely on the default `php` & `composer` binary for project commands. Use versioned binaries instead: `php81`, `php82`, `php83`, `composer81`, `composer82`, `composer83`
    - Tests may rely on a test database. In such case, do not run tests in parallel

    ## Pull request

    - Use `gh` CLI to interact with GitHub PRs
    - Follow the PR template in `.github/PULL_REQUEST_TEMPLATE.md`
      - If any sections don't apply, remove them instead of leaving placeholders.
      - Should have a clear, concise problem statement
      - Describe the approach and reasoning, not just the final code changes

    ## Skills

    - Prefer using skill codebase-memory over fd/rg whenever possible

    ## Guardrails

    - Do not make changes outside of the current working directory unless explicitly instructed by the user. If you need to make changes outside the current working directory, ask for confirmation first.
  '';
in

{
  home.packages = with pkgs; [
    github-copilot-cli
  ];

  programs.claude-code.enable = false;
  programs.claude-code.memory.text = global_instructions;

  programs.opencode.enable = false;
  programs.opencode.package = pkgs.unstable.opencode;
  programs.opencode.rules = global_instructions;
  programs.opencode.settings.share = "disabled";
  programs.opencode.settings.instructions = [ "AGENTS.local.md" ];
  programs.opencode.settings.experimental.disable_paste_summary = false;

  programs.codebase-memory-mcp.enable = true;

  home = {
    # Declaratively configure ~/.pi/agent/AGENTS.md
    file = {
      ".pi/agent/AGENTS.md".text = global_instructions;
    };
  };
}
