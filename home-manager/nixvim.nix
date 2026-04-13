{ config, lib, ... }:
let
  have_nerd_font = true;
in
{
  nixpkgs.useGlobalPackages = true;

  enable = true;
  defaultEditor = true;
  viAlias = true;
  vimAlias = true;
  vimdiffAlias = true;

  globalOpts = { };

  globals.mapleader = " ";
  globals.maplocalleader = " ";
  globals.have_nerd_font = have_nerd_font;

  localOpts = { };

  opts.number = true;
  opts.relativenumber = true;
  opts.mouse = "a";
  opts.showmode = false;
  opts.breakindent = true;
  opts.undofile = true;
  opts.ignorecase = true;
  opts.smartcase = true;
  opts.signcolumn = "yes";
  opts.updatetime = 250;
  opts.timeoutlen = 300;
  opts.splitright = true;
  opts.splitbelow = true;
  opts.list = true;
  opts.listchars.tab = "» ";
  opts.listchars.trail = "·";
  opts.listchars.nbsp = "␣";
  opts.inccommand = "split";
  opts.cursorline = true;
  opts.scrolloff = 10;
  opts.confirm = true;

  extraConfigLua = ''
    vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

    vim.api.nvim_create_autocmd('TextYankPost', {
      desc = 'Highlight when yanking (copying) text',
      group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
      callback = function() vim.hl.on_yank() end,
    })
  '';
  # clipboard.register = "unnamedplus";

  extraConfigLuaPost = "";

  diagnostic.settings.update_in_insert = false;
  diagnostic.settings.severity_sort = true;
  diagnostic.settings.float.border = "rounded";
  diagnostic.settings.float.source = "if_many";
  diagnostic.settings.underline.severity.min = lib.nixvim.mkRaw "vim.diagnostic.severity.WARN";

  diagnostic.settings.virtual_text = true;
  diagnostic.settings.virtual_lines = false;
  diagnostic.settings.jump.float = true;

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
      mode = "t";
      key = "<Esc><Esc>";
      action = "<C-\\><C-n>";
      options = {
        desc = "Exit terminal mode";
      };
    }

    {
      mode = "n";
      key = "<leader>q";
      action = lib.nixvim.mkRaw "vim.diagnostic.setloclist";
      options = {
        desc = "Open diagnostic [Q]uickfix list";
      };
    }

    {
      mode = "x";
      key = "p";
      action = lib.nixvim.mkRaw ''
        function() return 'pgv"' .. vim.v.register .. "y" end
      '';
      options = {
        remap = false;
        expr = true;
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
      key = "<leader>gg";
      action = "<cmd>LazyGit<cr>";
      options = {
        desc = "LazyGit";
      };
    }

    {
      mode = "n";
      key = "<leader>d";
      action = ":bd<CR>";
    }
  ];

  dependencies.lazygit.enable = true;
  # dependencies.copilot.enable = true;

  plugins.lz-n.enable = true;

  plugins.guess-indent.enable = true;

  plugins.which-key.enable = true;
  plugins.which-key.lazyLoad.enable = true;
  plugins.which-key.lazyLoad.settings.event = "VimEnter";
  plugins.which-key.settings.delay = 0;
  plugins.which-key.settings.icons.mappings = lib.nixvim.mkRaw "vim.g.have_nerd_font";
  plugins.which-key.settings.spec = [
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

  plugins.telescope.enable = true;
  plugins.telescope.lazyLoad.enable = true;
  plugins.telescope.lazyLoad.settings.event = "VimEnter";
  plugins.telescope.settings = { };
  plugins.telescope.luaConfig.content = ''
    -- plugins.telescope.luaConfig.content

    -- See `:help telescope.builtin`
    local builtin = require 'telescope.builtin'
    vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
    vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
    vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
    vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
    vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
    vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
    vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
    vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
    vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
    vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
    vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

    -- This runs on LSP attach per buffer (see main LSP attach function in 'neovim/nvim-lspconfig' config for more info,
    -- it is better explained there). This allows easily switching between pickers if you prefer using something else!
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
      callback = function(event)
        local buf = event.buf

        -- Find references for the word under your cursor.
        vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })

        -- Jump to the implementation of the word under your cursor.
        -- Useful when your language has ways of declaring types without an actual implementation.
        vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })

        -- Jump to the definition of the word under your cursor.
        -- This is where a variable was first declared, or where a function is defined, etc.
        -- To jump back, press <C-t>.
        vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })

        -- Fuzzy find all the symbols in your current document.
        -- Symbols are things like variables, functions, types, etc.
        vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })

        -- Fuzzy find all the symbols in your current workspace.
        -- Similar to document symbols, except searches over your entire project.
        vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })

        -- Jump to the type of the word under your cursor.
        -- Useful when you're not sure what type a variable is and you want to see
        -- the definition of its *type*, not where it was *defined*.
        vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
      end,
    })

    -- Override default behavior and theme when searching
    vim.keymap.set('n', '<leader>/', function()
      -- You can pass additional configuration to Telescope to change the theme, layout, etc.
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        winblend = 10,
        previewer = false,
      })
    end, { desc = '[/] Fuzzily search in current buffer' })

    -- It's also possible to pass additional configuration options.
    --  See `:help telescope.builtin.live_grep()` for information about particular keys
    vim.keymap.set(
      'n',
      '<leader>s/',
      function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end,
      { desc = '[S]earch [/] in Open Files' }
    )

    -- Shortcut for searching your Neovim configuration files
    vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config' } end, { desc = '[S]earch [N]eovim files' })
  '';
  plugins.telescope.extensions.ui-select.enable = true;
  plugins.telescope.extensions.ui-select.settings = { };
  plugins.telescope.extensions.fzf-native.enable = true;
  plugins.telescope.extensions.fzf-native.settings.case_mode = "smart_case";
  plugins.telescope.extensions.fzf-native.settings.fuzzy = true;
  plugins.telescope.extensions.fzf-native.settings.override_file_sorter = true;
  plugins.telescope.extensions.fzf-native.settings.override_generic_sorter = true;

  plugins.web-devicons.enable = have_nerd_font;

  plugins.luasnip.enable = true;

  plugins.blink-cmp.enable = true;
  plugins.blink-cmp.lazyLoad.enable = true;
  plugins.blink-cmp.lazyLoad.settings.event = "VimEnter";
  # plugins.blink-cmp.lazyLoad.settings.version = "1.*";
  plugins.blink-cmp.settings.keymap.preset = "default";
  plugins.blink-cmp.settings.appearance.nerd_font_variant = "mono";
  plugins.blink-cmp.settings.completion.documentation.auto_show = false;
  plugins.blink-cmp.settings.completion.documentation.auto_show_delay_ms = 500;
  plugins.blink-cmp.settings.sources.default = [
    "lsp"
    "path"
    "snippets"
  ];
  plugins.blink-cmp.settings.snippets.preset = "luasnip";
  plugins.blink-cmp.settings.fuzzy.implementation = "lua";
  plugins.blink-cmp.settings.signature.enabled = true;

  plugins.copilot-vim.enable = true;
  plugins.copilot-vim.lazyLoad.enable = true;
  plugins.copilot-vim.lazyLoad.settings.event = "VimEnter";

  # lsp.servers.copilot.enable = true;
  lsp.luaConfig.pre = ''
    -- LSP pre
  '';
  lsp.luaConfig.content = ''
    -- LSP content

    --  This function gets run when an LSP attaches to a particular buffer.
    --    That is to say, every time a new file is opened that is associated with
    --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
    --    function will be executed to configure the current buffer
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        -- NOTE: Remember that Lua is a real programming language, and as such it is possible
        -- to define small helper and utility functions so you don't have to repeat yourself.
        --
        -- In this case, we create a function that lets us more easily define mappings specific
        -- for LSP related items. It sets the mode, buffer and description for us each time.
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        -- Rename the variable under your cursor.
        --  Most Language Servers support renaming across files, etc.
        map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

        -- Execute a code action, usually your cursor needs to be on top of an error
        -- or a suggestion from your LSP for this to activate.
        map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

        -- WARN: This is not Goto Definition, this is Goto Declaration.
        --  For example, in C this would take you to the header.
        map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

        -- The following two autocommands are used to highlight references of the
        -- word under your cursor when your cursor rests there for a little while.
        --    See `:help CursorHold` for information about when this is executed
        --
        -- When you move your cursor, the highlights will be cleared (the second autocommand).
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client:supports_method('textDocument/documentHighlight', event.buf) then
          local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
            end,
          })
        end

        -- The following code creates a keymap to toggle inlay hints in your
        -- code, if the language server you are using supports them
        --
        -- This may be unwanted, since they displace some of your code
        if client and client:supports_method('textDocument/inlayHint', event.buf) then
          map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
        end
      end,
    })

    -- Enable the following language servers
    --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
    --  See `:help lsp-config` for information about keys and how to configure
    ---@type table<string, vim.lsp.Config>
    local servers = {
      -- clangd = {},
      -- gopls = {},
      -- pyright = {},
      -- rust_analyzer = {},
      --
      -- Some languages (like typescript) have entire language plugins that can be useful:
      --    https://github.com/pmizio/typescript-tools.nvim
      --
      -- But for many setups, the LSP (`ts_ls`) will work just fine
      -- ts_ls = {},

      stylua = {}, -- Used to format Lua code

      -- Special Lua Config, as recommended by neovim help docs
      lua_ls = {
        on_init = function(client)
          if client.workspace_folders then
            local path = client.workspace_folders[1].name
            if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
          end

          client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
            runtime = {
              version = 'LuaJIT',
              path = { 'lua/?.lua', 'lua/?/init.lua' },
            },
            workspace = {
              checkThirdParty = false,
              -- NOTE: this is a lot slower and will cause issues when working on your own configuration.
              --  See https://github.com/neovim/nvim-lspconfig/issues/3189
              library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file("", true), {
                "''${3rd}/luv/library",
                "''${3rd}/busted/library",
              }),
            },
          })
        end,
        settings = {
          Lua = {},
        },
      },
    }

    -- Ensure the servers and tools above are installed
    --
    -- To check the current status of installed tools and/or manually install
    -- other tools, you can run
    --    :Mason
    --
    -- You can press `g?` for help in this menu.
    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, {
      -- You can add other tools here that you want Mason to install
    })

    -- require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    for name, server in pairs(servers) do
      vim.lsp.config(name, server)
      vim.lsp.enable(name)
    end
  '';
  lsp.luaConfig.post = ''
    -- LSP post
  '';

  plugins.conform-nvim.enable = true;
  plugins.conform-nvim.lazyLoad.enable = true;
  plugins.conform-nvim.lazyLoad.settings.event = "BufWritePre";
  plugins.conform-nvim.lazyLoad.settings.cmd = "ConformInfo";
  plugins.conform-nvim.lazyLoad.settings.keys = [
    {
      __unkeyed-1 = "<leader>f";
      __unkeyed-3 = lib.nixvim.mkRaw ''
        function() require('conform').format { async = true, lsp_format = 'fallback' } end
      '';
      mode = "";
      desc = "[F]ormat buffer";
    }
  ];
  plugins.conform-nvim.settings.notify_on_error = false;
  plugins.conform-nvim.settings.format_on_save = lib.nixvim.mkRaw ''
    function(bufnr)
      -- Disable "format_on_save lsp_fallback" for languages that don't
      -- have a well standardized coding style. You can add additional
      -- languages here or re-enable it for the disabled ones.
      local disable_filetypes = { c = true, cpp = true }
      if disable_filetypes[vim.bo[bufnr].filetype] then
        return nil
      else
        return {
          timeout_ms = 500,
          lsp_format = 'fallback',
        }
      end
    end
  '';

  plugins.conform-nvim.settings.formatters_by_ft.lua = [ "stylua" ];
  plugins.conform-nvim.settings.formatters_by_ft.nix = [ "nixfmt" ];

  plugins.todo-comments.enable = true;
  plugins.todo-comments.lazyLoad.enable = true;
  plugins.todo-comments.lazyLoad.settings.event = "VimEnter";
  plugins.todo-comments.settings.signs = false;

  plugins.mini.enable = true;
  plugins.mini-ai.enable = true;
  plugins.mini-ai.settings.n_lines = 500;
  plugins.mini-surround.enable = true;
  plugins.mini-statusline.enable = true;
  plugins.mini-statusline.settings.use_icons = have_nerd_font;
  plugins.mini-statusline.luaConfig.post = ''
    -- plugins.mini-statusline.luaConfig.post

    -- You can configure sections in the statusline by overriding their
    -- default behavior. For example, here we set the section for
    -- cursor location to LINE:COLUMN
    ---@diagnostic disable-next-line: duplicate-set-field
    require('mini.statusline').section_location = function() return '%2l:%-2v' end
  '';

  plugins.treesitter.enable = true;
  plugins.treesitter.lazyLoad.enable = false;
  plugins.treesitter.luaConfig.pre = ''
    -- plugins.treesitter.luaConfig.pre
  '';
  plugins.treesitter.luaConfig.content = ''
    -- plugins.treesitter.luaConfig.content
  '';
  plugins.treesitter.luaConfig.post = ''
    -- plugins.treesitter.luaConfig.post
  '';
  plugins.treesitter.folding.enable = true;
  plugins.treesitter.highlight.enable = true;
  plugins.treesitter.indent.enable = true;
  plugins.treesitter.grammarPackages = with config.plugins.treesitter.package.builtGrammars; [
    bash
    c
    diff
    json
    html
    lua
    luadoc
    make
    markdown
    markdown_inline
    nix
    php
    query
    regex
    toml
    vim
    vimdoc
    xml
    yaml
  ];

  plugins.indent-blankline.enable = true;

  plugins.nvim-autopairs.enable = true;
  plugins.nvim-autopairs.lazyLoad.enable = true;
  plugins.nvim-autopairs.lazyLoad.settings.event = "InsertEnter";

  plugins.nui.enable = true;

  plugins.neo-tree.enable = true;
  plugins.neo-tree.settings.filesystem.window.mappings."\\" = "close_window";
  plugins.neo-tree.lazyLoad.enable = true;
  # plugins.neo-tree.lazyLoad.settings.version = "*";
  plugins.neo-tree.lazyLoad.settings.lazy = false;
  plugins.neo-tree.lazyLoad.settings.keys = [
    {
      __unkeyed-1 = "\\";
      __unkeyed-2 = ":Neotree reveal<CR>";
      desc = "NeoTree reveal";
      silent = true;
    }
  ];

  plugins.gitsigns.enable = true;
  plugins.gitsigns.settings.signs.add.text = "+";
  plugins.gitsigns.settings.signs.change.text = "~";
  plugins.gitsigns.settings.signs.changedelete.text = "~";
  plugins.gitsigns.settings.signs.delete.text = "_";
  pVlugins.gitsigns.settings.signs.topdelete.text = "‾";
  plugins.gitsigns.settings.on_attach = lib.nixvim.mkRaw ''
    function(bufnr)
      local gitsigns = require 'gitsigns'

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map('n', ']c', function()
        if vim.wo.diff then
          vim.cmd.normal { ']c', bang = true }
        else
          gitsigns.nav_hunk 'next'
        end
      end, { desc = 'Jump to next git [c]hange' })

      map('n', '[c', function()
        if vim.wo.diff then
          vim.cmd.normal { '[c', bang = true }
        else
          gitsigns.nav_hunk 'prev'
        end
      end, { desc = 'Jump to previous git [c]hange' })

      -- Actions
      -- visual mode
      map('v', '<leader>hs', function() gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [s]tage hunk' })
      map('v', '<leader>hr', function() gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [r]eset hunk' })
      -- normal mode
      map('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'git [s]tage hunk' })
      map('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'git [r]eset hunk' })
      map('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'git [S]tage buffer' })
      map('n', '<leader>hu', gitsigns.stage_hunk, { desc = 'git [u]ndo stage hunk' })
      map('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'git [R]eset buffer' })
      map('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'git [p]review hunk' })
      map('n', '<leader>hb', gitsigns.blame_line, { desc = 'git [b]lame line' })
      map('n', '<leader>hd', gitsigns.diffthis, { desc = 'git [d]iff against index' })
      map('n', '<leader>hD', function() gitsigns.diffthis '@' end, { desc = 'git [D]iff against last commit' })
      -- Toggles
      map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git show [b]lame line' })
      map('n', '<leader>tD', gitsigns.preview_hunk_inline, { desc = '[T]oggle git show [D]eleted' })
    end
  '';

  plugins.lazygit.enable = true;
  plugins.lazygit.settings.floating_window_use_plenary = 1;

  plugins.smart-splits.enable = true;
  plugins.smart-splits.lazyLoad.enable = true;
  plugins.smart-splits.lazyLoad.settings.event = "VimEnter";
  plugins.smart-splits.lazyLoad.settings.after = lib.nixvim.mkRaw ''
    function()
      -- recommended mappings
      -- resizing splits
      -- these keymaps will also accept a range,
      -- for example `10<A-h>` will `resize_left` by `(10 * config.default_amount)`
      vim.keymap.set('n', '<A-h>', require('smart-splits').resize_left)
      vim.keymap.set('n', '<A-j>', require('smart-splits').resize_down)
      vim.keymap.set('n', '<A-k>', require('smart-splits').resize_up)
      vim.keymap.set('n', '<A-l>', require('smart-splits').resize_right)
      -- moving between splits
      vim.keymap.set('n', '<C-h>', require('smart-splits').move_cursor_left)
      vim.keymap.set('n', '<C-j>', require('smart-splits').move_cursor_down)
      vim.keymap.set('n', '<C-k>', require('smart-splits').move_cursor_up)
      vim.keymap.set('n', '<C-l>', require('smart-splits').move_cursor_right)
      vim.keymap.set('n', '<C-\\>', require('smart-splits').move_cursor_previous)
      -- swapping buffers between windows
      vim.keymap.set('n', '<leader><leader>h', require('smart-splits').swap_buf_left)
      vim.keymap.set('n', '<leader><leader>j', require('smart-splits').swap_buf_down)
      vim.keymap.set('n', '<leader><leader>k', require('smart-splits').swap_buf_up)
      vim.keymap.set('n', '<leader><leader>l', require('smart-splits').swap_buf_right)
    end
  '';

  plugins.multicursors.enable = true;
  plugins.multicursors.lazyLoad.enable = true;
  plugins.multicursors.lazyLoad.settings.event = "DeferredUIEnter";
  plugins.multicursors.lazyLoad.settings.cmd = [
    "MCstart"
    "MCvisual"
    "MCclear"
    "MCpattern"
    "MCvisualPattern"
    "MCunderCursor"
  ];
  plugins.multicursors.lazyLoad.settings.keys = [
    {
      mode = [
        "v"
        "n"
      ];
      __unkeyed-2 = "<Leader>m";
      __unkeyed-3 = "<cmd>MCstart<CR>";
      desc = "Start [M]ulticursor";
    }
  ];

  colorschemes.tokyonight.enable = true;
  colorschemes.tokyonight.lazyLoad.enable = true;
  colorschemes.tokyonight.lazyLoad.settings.priority = 1000;
  colorschemes.tokyonight.settings.styles.comments.italic = false;
  colorschemes.tokyonight.settings.style = "night";
}
