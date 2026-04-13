{
  config,
  lib,
  pkgs,
  ...
}:

let
  global_instructions = ''
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

  '';
in

{
  home.packages = with pkgs; [
    copilot-cli
  ];

  programs.claude-code.enable = true;
  programs.claude-code.context = global_instructions;

  programs.opencode.enable = true;
  programs.opencode.package = pkgs.opencode-desktop;
  programs.opencode.context = global_instructions;
  programs.opencode.settings.share = "disabled";
}
