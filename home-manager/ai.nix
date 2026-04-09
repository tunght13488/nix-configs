{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.claude-code = {
    enable = true;
    memory.text = ''
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
    '';
  };
}
