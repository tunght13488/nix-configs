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

    Default shell is **zsh** with Prezto. The following aliases replace standard commands:

    | Alias | Actual Command |
    |-------|----------------|
    | `cat` | `bat --paging=never --style=plain` |
    | `find` | `fd` |
    | `grep` | `rg` (ripgrep) |
    | `ls` | `eza --group-directories-first` |
    | `du` | `ncdu` |

    When running shell commands, be aware these replacements affect syntax and flags.

    Do not use `command` e.g. command ls /nix/store/... as it asks for approval again and again. Run the actual command directly, e.g. `ls /nix/store/...`.

    ## PHP projects

    - Do not rely on the default `php` & `composer` binary for project commands.
    - Use `php81`, `php82`, `php83` explicitly for PHP CLI entrypoints so tooling runs on the project's supported version.
    - Use `composer81`, `composer82`, `composer83` explicitly for Composer commands to ensure dependencies are managed with the correct PHP version.
    - Apply this to commands such as:
      - `php81 ./vendor/bin/phpunit ...`
      - `php82 ./vendor/bin/php-cs-fixer ...`
      - `php83 ./vendor/bin/phpstan analyse --memory-limit=1G`
      - `composer81 install`
    - Check composer.json to confirm the required PHP version for the project and use the corresponding CLI binary.

    ## Pull request

    - Use `gh` CLI to interact with GitHub PRs
    - Follow the PR template in `.github/PULL_REQUEST_TEMPLATE.md`
      - If any sections don't apply, remove them instead of leaving placeholders.
      - Should have a clear, concise problem statement
      - Describe the approach and reasoning, not just the final code changes

  '';
in

{
  home.packages = with pkgs; [
    github-copilot-cli
  ];

  programs.claude-code.enable = true;
  programs.claude-code.memory.text = global_instructions;

  programs.opencode.enable = true;
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
