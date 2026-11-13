# Tasks

## 1. Shared base image

- [ ] 1.1 Add Debian's `neovim` package to `home-manager/pi-sandbox.Dockerfile` and set `EDITOR=nvim`, retaining `vim-tiny`; verify a base-image build, `nvim --version`, the `EDITOR` value, and that `git var GIT_EDITOR` remains `vi`.

## 2. Default configuration mount

- [x] 2.1 Reuse `append_config_mounts` in `home-manager/pi-box.sh` to mount `$HOME/.config/nvim` read-only at `/root/.config/nvim` when present; update the wrapper header and help text to list the new default grant. Verify `bash -n` and, with a temporary home and mocked Docker invocation, confirm the `:ro` mount is emitted only when the config directory exists.
- [x] 2.2 Run `make home-build` after the wrapper changes and verify Home Manager evaluation succeeds.

## 3. Repository documentation

- [x] 3.1 Update `AGENTS.md`'s default-grant and common-toolchain descriptions and the common-base comments in every shipped `home-manager/pi-box-templates/*/Dockerfile.pi`; verify the summaries include Neovim and the read-only config mount, without editing generated `openwiki/` pages.

## 4. Integration verification

- [ ] 4.1 Build a representative project image derived from `pi-sandbox` and verify `nvim --version`; in an interactive sandbox with no explicit Pi `externalEditor` setting, confirm Ctrl+G opens Neovim and returns the edited prompt to Pi.
- [ ] 4.2 With a host Neovim config present, verify it is readable but not writable inside the sandbox and inspect the default mounts to confirm no store-wide `/nix/store` or unrelated host mount is added (read-only targets of symlinked Neovim config entries are part of that config mount); also verify the sandbox still starts when the config directory is absent.
