# syntax=docker/dockerfile:1.7
# Base image for pi-box sandboxes.
#
# Deployed to ~/.pi/sandbox/Dockerfile by home-manager/pi-sandbox.nix and built
# on demand by the `pi-box` wrapper (tag: pi-sandbox). Per-project images are
# `FROM pi-sandbox`, so every layer here is shared across all projects.
#
# Layer order is stable-first, volatile-last: the Pi install is the final layer,
# so bumping PI_VERSION never invalidates the apt tooling layers below it.
ARG BASE_IMAGE=node:24-slim

# --- pinned Neovim plugin runtime (builder) --------------------------------
# The host's Nixvim config is mounted read-only and needs its plugins on the
# runtimepath. Those plugins, their native parts (Treesitter parsers, telescope's
# fzf sorter) must be built against THIS image's glibc: binaries built by Nix
# target a newer glibc and fail with "GLIBC_2.38 not found" on this base. So the
# sources are pinned to the exact revisions the repository's locked nixpkgs
# input resolves for the host config, and compiled here with the Debian
# toolchain. Nothing is installed at sandbox runtime and no host path is used.
#
# Refresh the tables below together with home-manager/nixvim.nix: they are the
# revisions nixpkgs selects for the enabled plugins and grammar packages.
FROM ${BASE_IMAGE} AS nvim-runtime
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      curl \
      unzip \
    && rm -rf /var/lib/apt/lists/*

# <pack name in the plugin pack>|<archive url>
RUN cat > /tmp/plugins.tsv <<'PLUGINS'
tokyonight-nvim|https://github.com/folke/tokyonight.nvim/archive/cdc07ac78467a233fd62c493de29a17e0cf2b2b6.tar.gz
nvim-web-devicons|https://github.com/nvim-tree/nvim-web-devicons/archive/v0.100.zip
which-key-nvim|https://github.com/folke/which-key.nvim/archive/3aab2147e74890957785941f0c1ad87d0a44c15a.tar.gz
nvim-treesitter|https://github.com/nvim-treesitter/nvim-treesitter/archive/4916d6592ede8c07973490d9322f187e07dfefac.tar.gz
todo-comments-nvim|https://github.com/folke/todo-comments.nvim/archive/refs/tags/v1.5.0.tar.gz
telescope-nvim|https://github.com/nvim-telescope/telescope.nvim/archive/7d324792b7943e4aa16ad007212e6acc6f9fe335.tar.gz
telescope-fzf-native-nvim|https://github.com/nvim-telescope/telescope-fzf-native.nvim/archive/b25b749b9db64d375d782094e2b9dce53ad53a40.tar.gz
telescope-ui-select-nvim|https://github.com/nvim-telescope/telescope-ui-select.nvim/archive/6e51d7da30bd139a6950adf2a47fda6df9fa06d2.tar.gz
plenary-nvim|https://github.com/nvim-lua/plenary.nvim/archive/74b06c6c75e4eeb3108ec01852001636d85a932b.tar.gz
smart-splits-nvim|https://github.com/mrjones2014/smart-splits.nvim/archive/3151100591670148cb0065388117622212208ee3.tar.gz
nvim-autopairs|https://github.com/windwp/nvim-autopairs/archive/7b9923abad60b903ece7c52940e1321d39eccc79.tar.gz
neo-tree-nvim|https://github.com/nvim-neo-tree/neo-tree.nvim/archive/refs/tags/3.41.0.tar.gz
nui-nvim|https://github.com/MunifTanjim/nui.nvim/archive/refs/tags/0.4.0.tar.gz
multicursors-nvim|https://github.com/smoka7/multicursors.nvim/archive/72225ea9e4443c3f4b9df91d0193e07c4ee8d382.tar.gz
hydra-nvim|https://github.com/nvimtools/hydra.nvim/archive/refs/tags/v1.0.3.tar.gz
mini-nvim|https://github.com/nvim-mini/mini.nvim/archive/264b5c8fc6e82212af0dc5c345145cfa916efeb6.tar.gz
luasnip|https://github.com/L3MON4D3/LuaSnip/archive/v2.5.0.zip
indent-blankline-nvim|https://github.com/lukas-reineke/indent-blankline.nvim/archive/refs/tags/v3.9.1.tar.gz
guess-indent-nvim|https://github.com/nmac427/guess-indent.nvim/archive/84a4987ff36798c2fc1169cbaff67960aed9776f.tar.gz
gitsigns-nvim|https://github.com/lewis6991/gitsigns.nvim/archive/a462f416e2ce4744531c6256252dee99a7d34a83.zip
conform-nvim|https://codeload.github.com/stevearc/conform.nvim/tar.gz/18aeab3d63d350dcf44d64c462cc489a3412af40
blink-cmp|https://github.com/Saghen/blink.cmp/archive/refs/tags/v1.10.2.tar.gz
copilot-vim|https://github.com/github/copilot.vim/archive/refs/tags/v1.59.0.tar.gz
lazygit-nvim|https://github.com/kdheepak/lazygit.nvim/archive/a04ad0dbc725134edbee3a5eea29290976695357.tar.gz
PLUGINS

# <language>|<source subdir>|<archive url>. Query files come from the
# nvim-treesitter plugin above, so only the compiled parser is needed.
RUN cat > /tmp/grammars.tsv <<'GRAMMARS'
bash||https://github.com/tree-sitter/tree-sitter-bash/archive/a06c2e4415e9bc0346c6b86d401879ffb44058f7.tar.gz
c||https://github.com/tree-sitter/tree-sitter-c/archive/ae19b676b13bdcc13b7665397e6d9b14975473dd.tar.gz
diff||https://github.com/tree-sitter-grammars/tree-sitter-diff/archive/2520c3f934b3179bb540d23e0ef45f75304b5fed.tar.gz
json||https://github.com/tree-sitter/tree-sitter-json/archive/001c28d7a29832b06b0e831ec77845553c89b56d.tar.gz
html||https://github.com/tree-sitter/tree-sitter-html/archive/73a3947324f6efddf9e17c0ea58d454843590cc0.tar.gz
lua||https://github.com/tree-sitter-grammars/tree-sitter-lua/archive/10fe0054734eec83049514ea2e718b2a56acd0c9.tar.gz
luadoc||https://github.com/tree-sitter-grammars/tree-sitter-luadoc/archive/873612aadd3f684dd4e631bdf42ea8990c57634e.tar.gz
make||https://github.com/tree-sitter-grammars/tree-sitter-make/archive/70613f3d812cbabbd7f38d104d60a409c4008b43.tar.gz
markdown|tree-sitter-markdown|https://github.com/tree-sitter-grammars/tree-sitter-markdown/archive/f969cd3ae3f9fbd4e43205431d0ae286014c05b5.tar.gz
markdown_inline|tree-sitter-markdown-inline|https://github.com/tree-sitter-grammars/tree-sitter-markdown/archive/f969cd3ae3f9fbd4e43205431d0ae286014c05b5.tar.gz
nix||https://github.com/nix-community/tree-sitter-nix/archive/eabf96807ea4ab6d6c7f09b671a88cd483542840.tar.gz
php|php|https://github.com/tree-sitter/tree-sitter-php/archive/3f2465c217d0a966d41e584b42d75522f2a3149e.tar.gz
query||https://github.com/tree-sitter-grammars/tree-sitter-query/archive/fc5409c6820dd5e02b0b0a309d3da2bfcde2db17.tar.gz
regex||https://github.com/tree-sitter/tree-sitter-regex/archive/b2ac15e27fce703d2f37a79ccd94a5c0cbe9720b.tar.gz
toml||https://github.com/tree-sitter-grammars/tree-sitter-toml/archive/64b56832c2cffe41758f28e05c756a3a98d16f41.tar.gz
vim||https://github.com/tree-sitter-grammars/tree-sitter-vim/archive/3092fcd99eb87bbd0fc434aa03650ba58bd5b43b.tar.gz
vimdoc||https://github.com/neovim/tree-sitter-vimdoc/archive/f061895a0eff1d5b90e4fb60d21d87be3267031a.tar.gz
xml|xml|https://github.com/tree-sitter-grammars/tree-sitter-xml/archive/5000ae8f22d11fbe93939b05c1e37cf21117162d.tar.gz
yaml||https://github.com/tree-sitter-grammars/tree-sitter-yaml/archive/4463985dfccc640f3d6991e3396a2047610cf5f8.tar.gz
GRAMMARS

RUN set -eu; \
    site=/out/site; \
    mkdir -p "$site/pack/dist/start" "$site/parser"; \
    while IFS='|' read -r name url; do \
      [ -n "$name" ] || continue; \
      tmp="$(mktemp -d)"; \
      curl -fsSL "$url" -o "$tmp/archive"; \
      mkdir -p "$tmp/x"; \
      case "$url" in \
        *.zip) unzip -q "$tmp/archive" -d "$tmp/x" ;; \
        *) tar -xzf "$tmp/archive" -C "$tmp/x" ;; \
      esac; \
      mv "$(find "$tmp/x" -mindepth 1 -maxdepth 1 -type d | head -1)" "$site/pack/dist/start/$name"; \
      rm -rf "$tmp"; \
    done < /tmp/plugins.tsv; \
    make -C "$site/pack/dist/start/telescope-fzf-native-nvim"; \
    while IFS='|' read -r lang subdir url; do \
      [ -n "$lang" ] || continue; \
      tmp="$(mktemp -d)"; \
      curl -fsSL "$url" -o "$tmp/archive"; \
      mkdir -p "$tmp/x"; \
      tar -xzf "$tmp/archive" -C "$tmp/x"; \
      src="$(find "$tmp/x" -mindepth 1 -maxdepth 1 -type d | head -1)/$subdir"; \
      if [ -f "$src/src/scanner.c" ]; then \
        cc -O2 -shared -fPIC -I"$src/src" "$src/src/parser.c" "$src/src/scanner.c" -o "$site/parser/$lang.so"; \
      else \
        cc -O2 -shared -fPIC -I"$src/src" "$src/src/parser.c" -o "$site/parser/$lang.so"; \
      fi; \
      rm -rf "$tmp"; \
    done < /tmp/grammars.tsv; \
    rm -f /tmp/plugins.tsv /tmp/grammars.tsv

FROM ${BASE_IMAGE}

# --- stable layers: OS tooling ---------------------------------------------
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      fd-find \
      gh \
      git \
      jq \
      less \
      python3 \
      ripgrep \
      unzip \
      vim-tiny \
      xz-utils \
    && rm -rf /var/lib/apt/lists/* \
    # Debian installs the binary as `fdfind`; pi probes for `fd` or `fdfind`,
    # this symlink is for humans at the shell.
    && ln -sf "$(command -v fdfind)" /usr/local/bin/fd

# --- stable layer: pinned Neovim -------------------------------------------
# Debian's neovim is 0.7.x on this base, too old for the host's Nixvim config
# (0.11+ APIs such as vim.lsp.config). Use the official release tarball instead,
# pinned by version and checksum; bump both together with NVIM_SHA256.
# `vim` points at Neovim too, mirroring the host, where Nixvim aliases vim to
# nvim: the shared Pi settings set externalEditor to "vim". Debian's vim-tiny
# only ships `vim.tiny` (as `vi`), which is what git's core.editor keeps using.
ARG NVIM_VERSION=0.12.6
ARG NVIM_SHA256=474430d53e6264f6d6dd18db42d6dc9df3a1b56ca9e88a325bbf860e1a811d87
RUN curl -fsSLo /tmp/nvim.tar.gz \
      "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-x86_64.tar.gz" \
    && echo "${NVIM_SHA256}  /tmp/nvim.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/nvim.tar.gz -C /opt \
    && ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim \
    && ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/vim \
    && rm /tmp/nvim.tar.gz

ENV EDITOR=nvim

# --- stable layer: Neovim plugin runtime -----------------------------------
# Built in the nvim-runtime stage above: the pack the mounted host config loads
# from, plus compiled Treesitter parsers for its enabled languages.
COPY --from=nvim-runtime /out/site /usr/local/share/nvim/site

# Neovim and its plugins write logs, undo files and shada under these paths. The
# image ships no such scaffolding, and plugins that open their log eagerly
# (neo-tree) warn on every start when the directory is missing.
RUN mkdir -p /root/.local/share/nvim /root/.local/state/nvim /root/.cache/nvim

# --- stable layer: container-safe git overrides ----------------------------
# pi-box mounts the host's ~/.config/git read-only at /root/.config/git. Git
# reads this file (~/.gitconfig) after the XDG global config, so single-valued
# settings here win, and an empty credential.helper resets the accumulator -
# which drops the host's /nix/store credential-helper path (absent in here).
#
# The url.*.insteadOf entry lets GitHub SCP-style SSH remotes (`git@github.com:`)
# resolve over HTTPS, where the gh credential helper above can authenticate them.
# No SSH agent is ever mounted, so without this every SSH-form remote would fail.
# The rewrite is transport-level only: each checkout keeps its configured origin.
RUN cat > /root/.gitconfig <<'GITCONFIG'
[credential]
	helper =
[credential "https://github.com"]
	helper = ""
	helper = /usr/bin/gh auth git-credential
[credential "https://gist.github.com"]
	helper = ""
	helper = /usr/bin/gh auth git-credential
[url "https://github.com/"]
	insteadOf = git@github.com:
[core]
	editor = vi
	askpass =
[diff]
	tool =
[merge]
	tool =
[difftool]
	prompt = false
[mergetool]
	prompt = false
GITCONFIG

# --- volatile layer: Pi itself ---------------------------------------------
# Pinned by the wrapper's --build-arg so the image tracks the host Pi version.
ARG PI_VERSION=latest
RUN npm install -g --ignore-scripts "@earendil-works/pi-coding-agent@${PI_VERSION}" \
    && npm cache clean --force

WORKDIR /workspace
CMD ["pi"]
