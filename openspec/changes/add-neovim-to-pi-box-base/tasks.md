# Tasks

## 1. Shared base image

- [ ] 1.1 Replace Debian Neovim with the official v0.12.6 Linux x86_64 tarball in `home-manager/pi-sandbox.Dockerfile`, pinning its version and SHA-256 (`474430d53e6264f6d6dd18db42d6dc9df3a1b56ca9e88a325bbf860e1a811d87`); set `EDITOR=nvim` and retain `vim-tiny`. Verify the base-image build checks the digest, `nvim --version` reports v0.12.6, and `git var GIT_EDITOR` remains `vi`.
- [ ] 1.2 Bundle the pinned plugin/runtime dependencies enabled by `home-manager/nixvim.nix`—including TokyoNight, transitive dependencies, native components, and configured Tree-sitter grammars—into the image's Neovim site runtime path. Verify a headless startup with the mounted host config reports no missing plugin modules and does not need host plugin/Nix-store mounts.

## 2. Default configuration mount

- [x] 2.1 Reuse `append_config_mounts` in `home-manager/pi-box.sh` to mount `$HOME/.config/nvim` read-only at `/root/.config/nvim` when present; update the wrapper header and help text to list the new default grant. Verify `bash -n` and, with a temporary home and mocked Docker invocation, confirm the `:ro` mount is emitted only when the config directory exists.
- [x] 2.2 Run `make home-build` after the wrapper changes and verify Home Manager evaluation succeeds.

## 3. Repository documentation

- [x] 3.1 Update `AGENTS.md`'s default-grant and common-toolchain descriptions and the common-base comments in every shipped `home-manager/pi-box-templates/*/Dockerfile.pi`; verify the summaries include Neovim and the read-only config mount, without editing generated `openwiki/` pages.

## 4. Integration verification

- [ ] 4.1 Build a representative project image derived from `pi-sandbox`; verify it inherits Neovim v0.12.6 and that interactive Ctrl+G opens the mounted host config with TokyoNight, returns to Pi, and restores the edited prompt.
- [ ] 4.2 With a host Neovim config present, verify the mount is readable but not writable; inspect default mounts to confirm no host plugin/Nix-store closure or unrelated path is mounted (resolved config-file symlink targets remain part of the config mount); also verify the sandbox starts when the config directory is absent.
