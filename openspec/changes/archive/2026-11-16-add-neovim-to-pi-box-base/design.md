# Design

## Context

The shared `pi-sandbox` image is based on `node:24-slim`. The current implementation installs Debian's Neovim package, which the user observed as v0.7.2; the host runs v0.12.4. `home-manager/nixvim.nix` configures TokyoNight and a larger plugin set, including Telescope and extensions, blink.cmp, LuaSnip, mini.nvim, Treesitter with configured grammars, Neo-tree, Gitsigns, and other plugins. The sandbox receives the host's Neovim config read-only, but not the plugin runtime currently supplied by the host Nixvim package set.

At this plan update the official latest stable release is Neovim v0.12.6. The official Linux x86_64 tarball is `nvim-linux-x86_64.tar.gz` with SHA-256 `474430d53e6264f6d6dd18db42d6dc9df3a1b56ca9e88a325bbf860e1a811d87` ([release](https://github.com/neovim/neovim/releases/tag/v0.12.6)). TokyoNight's current README requires Neovim >=0.8.0 ([requirements](https://github.com/folke/tokyonight.nvim#requirements)).

Implementation finding: plugin sources and Treesitter parsers taken from nixpkgs cannot be used as-is. The parsers are linked against nixpkgs' glibc and fail to load on this base with `GLIBC_2.38 not found` (base is Debian bookworm, glibc 2.36). The pinned *sources* are still the right pin, but native artifacts must be compiled with the image's own Debian toolchain.

`home-manager/pi-box.sh` already uses `append_config_mounts` for read-only host configuration, including resolved targets for symlinked config files, and skips absent directories. The shared image's Git config intentionally keeps `core.editor=vi`.

## Goals / Non-Goals

**Goals:**
- Provide pinned Neovim v0.12.6 (latest stable at this plan update) as Pi's default Ctrl+G editor in the base and derived images.
- Make the plugin runtime needed by the mounted host Nixvim config, including TokyoNight and its transitive/native runtime assets, available from the image.
- Keep `~/.config/nvim` read-only and avoid host Nix-store mounts for plugin/runtime dependencies.
- Preserve explicit Pi `externalEditor` precedence and Git's separate `vi` editor fallback.

**Non-Goals:**
- Mounting the host's Nix store or allowing Neovim to change host configuration.
- Changing the host Nixvim configuration or project-specific toolchains.
- Installing or updating plugins at sandbox runtime.

## Decisions

- Replace Debian's Neovim package with the official v0.12.6 Linux x86_64 tarball. Pin both release version and SHA-256 in the stable base-image layer, install its bundled runtime under `/opt`, and expose `nvim` on `PATH`. Use the tarball rather than the AppImage to avoid a FUSE runtime dependency. Keep `vim-tiny`, set `EDITOR=nvim`, and leave the Git `core.editor=vi` override intact. Refresh the version and checksum together when intentionally upgrading to a newer stable release.
- Package the plugins enabled by `home-manager/nixvim.nix`, their transitive plugin dependencies, and its configured Tree-sitter grammars in the image's standard Neovim site runtime path. Download the pinned sources in a builder stage and compile the native parts there with the Debian toolchain (Treesitter parsers, telescope's fzf sorter), then copy only the assembled `site` tree into the final image. Pins are the revisions the repository's locked nixpkgs input resolves, so the mounted config sees matching plugin versions; queries come from the nvim-treesitter plugin itself, so only compiled parsers need building. Compiling here, rather than reusing nixpkgs' built outputs, avoids the glibc mismatch above and keeps build tooling out of the runtime image.
- Keep using `append_config_mounts` for `~/.config/nvim` to `/root/.config/nvim`. The existing read-only mount of a symlinked config file's resolved target remains part of the requested config mount; do not add mounts for plugin closures or the full Nix store.
- Keep the existing wrapper grant text and repository/template documentation changes. Do not hand-edit generated `openwiki/` pages.

## Risks / Trade-offs

- [Plugin set can drift from `nixvim.nix`] → Pins live in two tables in `home-manager/pi-sandbox.Dockerfile`; refresh them with the configured plugin set, and verify headless startup using the mounted config.
- [Native plugin/parser builds can fail or be platform-specific] → Build them in the Debian builder stage of the image (not with Nix, whose binaries need a newer glibc) and smoke-test the base plus a derived project image.
- [Plugin pack inflates the shared base image] → Only the assembled site tree is copied into the final stage; build tooling stays in the discarded builder stage. Accepted cost of making the mounted config work without host Nix-store access.
- [A later Neovim release may supersede v0.12.6] → Keep a reproducible version/checksum pair; refresh both when updating the pinned stable release rather than using an unverified floating URL.
- [Read-only config may still refer to files outside the config directory] → Keep the host grant limited to the requested config (including its resolved config-file symlinks); plugin/runtime dependencies must come from the image, and the integration check must confirm no plugin-store mount is added.
- [Config still points at host-only tool paths] → The generated config sets `copilot_node_command`, `python3_host_prog`, and `ruby_host_prog` to host store paths that do not exist in the sandbox, so Copilot and the Python/Ruby providers stay inactive there; the providers are unneeded for editing, and Copilot would need a container-local Node path if it is wanted later.

## Migration Plan

1. Build the base image with the pinned Neovim and image-local plugin runtime; verify the release checksum, `nvim --version`, Git's `vi` fallback, and headless startup of the mounted host config.
2. Run `make home-build` for the wrapper/config changes, then have the user apply Home Manager. The next `pi-box` run rebuilds the shared image automatically.
3. Verify Ctrl+G opens the mounted-config Neovim, TokyoNight loads, and edits return to Pi; inspect mounts to confirm config is read-only and no host plugin/Nix-store closure is mounted.
4. To roll back, revert the Home Manager and base-image changes and apply the prior Home Manager generation; `pi-box` rebuilds the shared base on its next run.
