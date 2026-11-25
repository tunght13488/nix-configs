# Design

## Context

`home-manager/home.nix` imports `home-manager/ai.nix`, which currently installs `github-copilot-cli`; the Neovim Copilot plugin is configured separately. `pkgs/default.nix` exposes custom packages through both the additions overlay and flake package outputs. `pkgs/obsidian.nix` is the local precedent for wrapping a pinned official AppImage with `appimageTools` and installing its desktop metadata. NixOS AppImage support is already enabled and does not need to change.

The AppImage FHS environment inherits `appimageTools.defaultFhsEnvArgs.multiPkgs`, which supplies GnuTLS-linked `curlWithGnuTls`. The app's cached Git HTTPS helper requires the OpenSSL-linked `CURL_OPENSSL_4` ABI; the inherited library only exports `CURL_GNUTLS_4`, causing repository clones to fail.

GitHub's [Copilot app quickstart](https://docs.github.com/en/copilot/get-started/quickstart-copilot-app) links to Linux downloads. The official [`github/app` releases](https://github.com/github/app/releases/latest) publish a Linux x86_64 AppImage; at planning time, the latest release is v1.5.0 and its AppImage is about 612 MB.

## Goals / Non-Goals

**Goals:**

- Provide a reproducible x86_64 Linux package from an official release.
- Install it through the existing Home Manager AI package list and make it available in GNOME's application grid.
- Keep the CLI and Neovim Copilot configuration independent and unchanged.
- Make HTTPS clone operations work with the Git helper bundled by the app.

**Non-Goals:**

- Add support for other operating systems or Linux architectures.
- Change Copilot authentication, app settings, repositories, or user data.
- Add a flake input, alter system AppImage settings, or manage app self-updates.

## Decisions

1. **Wrap the official Linux x86_64 AppImage as a custom package.** Use a versioned release URL and fixed SHA-256 hash with `appimageTools.wrapType2`, following `pkgs/obsidian.nix`. This reuses an established local pattern and avoids changing flake inputs. Recheck the current official release when implementing; v1.5.0 was current during planning.
   - Alternative considered: install the upstream `.deb` or `.rpm`. The AppImage matches the existing packaging pattern and avoids introducing distro-package extraction logic.

2. **Expose and install it through existing layers.** Add the package to `pkgs/default.nix` and install it in `home-manager/ai.nix`, alongside—but separately from—`github-copilot-cli`. The flake's package output and the `pkgs` overlay are already generated from `pkgs/default.nix`.
   - Alternative considered: add another Home Manager module. The existing AI module already owns the CLI and is the smaller, consistent place for this package.

3. **Integrate the upstream launcher metadata.** Inspect the AppImage's desktop entry and icons, install them into the package, and retarget the desktop entry to the wrapped executable so the app appears in GNOME's grid. Verify the actual upstream `Exec` value rather than assuming it matches another AppImage.

4. **Use the compatible curl ABI only in this app's FHS runtime.** Override `multiPkgs` to remove `curlWithGnuTls` from the inherited AppImage set and add `pkgs.curl`, which exports `CURL_OPENSSL_4`. This keeps the fix scoped to GitHub Copilot rather than changing NixOS or other AppImages.
   - Alternative considered: change system-wide `nix-ld` libraries or replace the app's cached Git helper. Both broaden the change beyond the app package.

5. **Keep updates declarative.** Update the package by changing its pinned version and hash; do not advance `flake.lock`. App self-update behavior is not part of this change.

## Risks / Trade-offs

- **The upstream AppImage is large (about 612 MB at planning time).** The first uncached build requires a substantial download and store space; pinning its hash keeps the fetched artifact reproducible.
- **The upstream Git helper can depend on a different libcurl TLS backend than the AppImage defaults.** Keep the OpenSSL curl override package-scoped and inspect the resulting FHS library's exported ABI; verify HTTPS cloning after Home Manager activation.
- **The AppImage may need app-specific launcher adjustments.** Build the package and inspect its desktop metadata; smoke-test launching it from the package and GNOME grid before activating the Home Manager generation.
- **The upstream release may advance before implementation.** Recheck the official release asset and pin its version and hash together; do not use a floating `latest` URL.

## Migration Plan

There is no data migration. A Home Manager activation adds the app while leaving the CLI and existing app data untouched. To roll back, remove the package from the Home Manager list and revert its package/export changes, then rebuild and activate the prior configuration; do not delete user data created by the app.
