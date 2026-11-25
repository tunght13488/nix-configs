# Tasks

## 1. Package the official desktop app

- [x] 1.1 Add a pinned x86_64 Linux AppImage package in `pkgs/github-copilot-app.nix`, expose it through `pkgs/default.nix`, and wire its desktop entry and icon to the wrapped executable; replace GnuTLS `curlWithGnuTls` with OpenSSL-backed `pkgs.curl` in this app's FHS `multiPkgs`. Stage the new Nix file before evaluation, then verify with `nix build .#github-copilot-app`, inspect the launcher and icon, and confirm the FHS libcurl exports `CURL_OPENSSL_4`.


## 2. Install and validate through Home Manager

- [x] 2.1 Add the app to `home-manager/ai.nix` without removing `github-copilot-cli`; run `make format` and `make home-build`, and confirm the existing CLI and Neovim Copilot configuration remain unchanged.
- [x] 2.2 After a human activates the Home Manager generation, launch the app from GNOME's application grid, clone a GitHub repository over HTTPS, and verify the clone succeeds without a libcurl symbol error and the existing Copilot CLI remains usable.
