# Tasks

## 1. Package the official Orca AppImage

- [x] 1.1 Prefetch the pinned AppImage (`nix store prefetch-file --json https://github.com/stablyai/orca/releases/download/v1.4.279/orca-linux.AppImage`) and extract it once (AppImage `--appimage-extract` or `appimageTools.extractType2` on the fetched file) to record the inner binary name(s) and the desktop entry files with their `Exec=` lines; verify the extraction output lists the `orca-ide` binary and at least one `.desktop` entry.
- [x] 1.2 Create `pkgs/orca.nix` modeled on `pkgs/github-copilot-app.nix`: `appimageTools.wrapType2` with `version = "1.4.279"` and the prefetched SRI hash, `extraInstallCommands` that copies upstream desktop entries, retargets their `Exec=` to the wrapper binary, and symlinks the inner `orca-ide` binary into `$out/bin`; add the standard header with update instructions. `git add pkgs/orca.nix`, then verify `nix build .#orca-app` succeeds and `result/bin/` contains `orca-app` and `orca-ide`.
- [x] 1.3 Register `orca-app` in `pkgs/default.nix` under the `additions` overlay; verify `nix eval --raw .#orca-app.name` prints `orca-app`.

## 2. Install via Home Manager

- [x] 2.1 Add `orca-app` to `home.packages` in `home-manager/ai.nix` alongside `github-copilot-app`; verify `make home-build` succeeds.
- [x] 2.2 Run `make format` and verify the changed files are formatted with no unrelated diff.
- [x] 2.3 Inspect the evaluated Home Manager generation closure and verify `orca-app` (with `bin/orca-app` and `bin/orca-ide`) is present while nixpkgs' GNOME screen-reader `orca` is unchanged.

## 3. Verify on the desktop (user-run)

- [x] 3.1 Run `make home` and verify Orca launches from the GNOME application grid with its icon.
- [x] 3.2 Run `orca-ide` in a shell and verify the Orca CLI responds (usage or registration prompt), confirming the spec's CLI requirement on the live system.

## Workflow follow-up

- Archive the change (`/opsx-archive`) after the desktop verification passes.
- If the app fails to launch from GNOME (missing system libraries), adjust the `fhsPkgs` list in `pkgs/orca.nix` per the copilot-app libcurl precedent and repeat group 3.
