# nixvim.nix
{ lib, ... }:
let
  have_nerd_font = true;
in
{
  # # You can use lib.nixvim in your config
  # fooOption = lib.nixvim.mkRaw "print('hello')";

  # # Configure Nixvim without prefixing with `plugins.nixvim`
  # plugins.my-plugin.enable = true;

  enable = true;
  defaultEditor = true;
  viAlias = true;
  vimAlias = true;
  vimdiffAlias = true;

  globalOpts = { };

  globals = {
    mapleader = " ";
    maplocalleader = " ";
    have_nerd_font = have_nerd_font;
  };

  localOpts = { };

  opts = {
    number = true;
    relativenumber = true;
    mouse = "a";
    showmode = false;
    breakindent = true;
    undofile = true;
    ignorecase = true;
    smartcase = true;
    signcolumn = "yes";
    updatetime = 250;
    timeoutlen = 300;
    splitright = true;
    splitbelow = true;
    list = true;
    listchars = {
      tab = "» ";
      trail = "·";
      nbsp = "␣";
    };
    inccommand = "split";
    cursorline = true;
    scrolloff = 10;
    confirm = true;
  };

  extraConfigLua = ''
    vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)
  '';
  # clipboard.register = "unnamedplus";

  extraConfigLuaPost = "";

  diagnostic.settings = {
    update_in_insert = false;
    severity_sort = true;
    float = {
      border = "rounded";
      source = "if_many";
    };
    underline = {
      severity = {
        min = {
          __raw = "vim.diagnostic.severity.WARN";
        };
      };
    };
    virtual_text = true;
    virtual_lines = false;
    jump = {
      float = true;
    };
  };

  keymaps = [
    {
      mode = "i";
      key = "jk";
      action = "<Esc>";
    }
    {
      mode = "n";
      key = "<Esc>";
      action = "<cmd>nohlsearch<CR>";
    }
    {
      mode = "n";
      key = ";";
      action = ":";
    }

    {
      mode = "n";
      key = "<leader>q";
      action = {
        __raw = "vim.diagnostic.setloclist";
      };
      options = {
        desc = "Open diagnostic [Q]uickfix list";
      };
    }

    {
      mode = [
        "n"
        "i"
      ];
      key = "<Up>";
      action = "<NOP>";
    }
    {
      mode = [
        "n"
        "i"
      ];
      key = "<Down>";
      action = "<NOP>";
    }
    {
      mode = [
        "n"
        "i"
      ];
      key = "<Left>";
      action = "<NOP>";
    }
    {
      mode = [
        "n"
        "i"
      ];
      key = "<Right>";
      action = "<NOP>";
    }

    {
      mode = "n";
      key = "<C-h>";
      action = "<C-w><C-h>";
      options = {
        desc = "Move focus to the left window";
      };
    }
    {
      mode = "n";
      key = "<C-l>";
      action = "<C-w><C-l>";
      options = {
        desc = "Move focus to the right window";
      };
    }
    {
      mode = "n";
      key = "<C-j>";
      action = "<C-w><C-j>";
      options = {
        desc = "Move focus to the lower window";
      };
    }
    {
      mode = "n";
      key = "<C-k>";
      action = "<C-w><C-k>";
      options = {
        desc = "Move focus to the upper window";
      };
    }

    {
      mode = "n";
      key = "\\";
      action = ":Neotree reveal<CR>";
      options = {
        desc = "NeoTree reveal";
        silent = true;
      };
    }

    {
      mode = "n";
      key = "<leader>gg";
      action = "<cmd>LazyGit<cr>";
      options = {
        desc = "LazyGit";
      };
    }
  ];

  dependencies.lazygit.enable = true;

  plugins.lz-n.enable = true;

  plugins.guess-indent.enable = true;

  plugins.gitsigns = {
    enable = true;
    settings = {
      signs = {
        add = {
          text = "+";
        };
        change = {
          text = "~";
        };
        changedelete = {
          text = "~";
        };
        delete = {
          text = "_";
        };
        topdelete = {
          text = "‾";
        };
      };
    };
  };

  plugins.which-key = {
    enable = true;
    lazyLoad = {
      enable = true;
      settings = {
        event = "VimEnter";
      };
    };
    settings = {
      delay = 0;
      icons = {
        mappings = {
          __raw = "vim.g.have_nerd_font";
        };
      };
      spec = [
        {
          __unkeyed-1 = "<leader>s";
          group = "[S]earch";
          mode = [
            "n"
            "v"
          ];
        }
        {
          __unkeyed-1 = "<leader>t";
          group = "[T]oggle";
        }
        {
          __unkeyed-1 = "<leader>h";
          group = "Git [H]unk";
          mode = [
            "n"
            "v"
          ];
        }
        {
          __unkeyed-1 = "gr";
          group = "LSP Actions";
          mode = "n";
        }
      ];
    };
  };

  plugins.telescope = {
    enable = true;
    lazyLoad = {
      enable = true;
      settings = {
        event = "VimEnter";
      };
    };
    settings = { };
    luaConfig = {
      pre = ''
        -- telescope pre
      '';
      content = ''
        -- telescope content
        local t_builtin = require 'telescope.builtin'
        vim.keymap.set('n', '<leader>sh', t_builtin.help_tags, { desc = '[S]earch [H]elp' })
        vim.keymap.set('n', '<leader>sk', t_builtin.keymaps, { desc = '[S]earch [K]eymaps' })
        vim.keymap.set('n', '<leader>sf', t_builtin.find_files, { desc = '[S]earch [F]iles' })
        vim.keymap.set('n', '<leader>ss', t_builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
        vim.keymap.set({ 'n', 'v' }, '<leader>sw', t_builtin.grep_string, { desc = '[S]earch current [W]ord' })
        vim.keymap.set('n', '<leader>sg', t_builtin.live_grep, { desc = '[S]earch by [G]rep' })
        vim.keymap.set('n', '<leader>sd', t_builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
        vim.keymap.set('n', '<leader>sr', t_builtin.resume, { desc = '[S]earch [R]esume' })
        vim.keymap.set('n', '<leader>s.', t_builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
        vim.keymap.set('n', '<leader>sc', t_builtin.commands, { desc = '[S]earch [C]ommands' })
        vim.keymap.set('n', '<leader><leader>', t_builtin.buffers, { desc = '[ ] Find existing buffers' })
      '';
      post = ''
        -- telescope post
      '';
    };
    extensions = {
      ui-select = {
        enable = true;
        settings = { };
      };
      fzf-native = {
        enable = true;
        settings = {
          case_mode = "smart_case";
          fuzzy = true;
          override_file_sorter = true;
          override_generic_sorter = true;
        };
      };
    };
  };

  plugins.web-devicons.enable = have_nerd_font;

  plugins.neo-tree = {
    enable = true;
    settings = {
      filesystem = {
        window = {
          mappings = {
            "\\" = "close_window";
          };
        };
      };
    };
  };

  plugins.lazygit = {
    enable = true;
    settings = {
      floating_window_use_plenary = 1;
    };
  };
}
