# Orca desktop IDE, wrapped from the official upstream AppImage.
#
# Upstream (https://github.com/stablyai/orca) ships Linux only as an AppImage;
# this wraps it using the same approach as Obsidian and the GitHub Copilot app
# (see pkgs/obsidian.nix, pkgs/github-copilot-app.nix).
#
# The attribute is `orca-app`, not `orca`: nixpkgs already owns `orca` with the
# GNOME screen reader, and shadowing it would silently change that package for
# every consumer of the `additions` overlay.
#
# On Linux upstream names the binary and the CLI `orca-ide`, because GNOME's
# screen reader owns `/usr/bin/orca`. The AppImage bundles one Electron binary
# that serves both the GUI and the CLI, so `$out/bin/orca-ide` is a symlink to
# the wrapper and both entry points run the same program.
#
# Consumed two ways:
#   1. As a flake output:  nix build .#orca-app
#   2. Via the `additions` overlay:  pkgs.orca-app (installed in
#      home-manager/ai.nix).  MIT licensed, so no allowUnfree escape hatch.
#
# Updating: bump `version`, then
#   nix store prefetch-file --json https://github.com/stablyai/orca/releases/download/v<version>/orca-linux.AppImage
# and paste the printed `hash` (SRI) below. No flake input changes are involved.
# Only the x86_64 AppImage is pinned; other architectures are unsupported here.

{ lib
, appimageTools
, fetchurl
,
}:

let
  pname = "orca-app";
  version = "1.4.279";

  src = fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux.AppImage";
    hash = "sha256-cqDNX1ywnGmw2ZjKJV3+NapL9/IhRfLSGLkjk8twzVo=";
  };

  # Extracted separately so upstream's own desktop entry and icon theme can be
  # reused instead of maintained by hand.
  extracted = appimageTools.extractType2 {
    inherit
      pname
      version
      src
      ;
  };
in
appimageTools.wrapType2 {
  inherit
    pname
    version
    src
    ;

  extraInstallCommands = ''
    mkdir -p $out/share
    cp -r ${extracted}/usr/share/icons $out/share/

    # Upstream launches its inner `orca-ide` binary through AppRun; point the
    # entry at the FHS wrapper in $out/bin instead. Entries are copied rather
    # than symlinked so they stay writable.
    mkdir -p $out/share/applications
    shopt -s nullglob
    found=
    for entry in ${extracted}/*.desktop ${extracted}/usr/share/applications/*.desktop; do
      found=1
      dest="$out/share/applications/$(basename "$entry")"
      install -Dm644 "$entry" "$dest"
      substituteInPlace "$dest" --replace-fail 'Exec=AppRun' "Exec=${pname}"
    done
    test -n "$found" \
      || { echo "upstream AppImage ships no desktop entry" >&2; exit 1; }

    # CLI entry point. Upstream registers the CLI as `orca-ide` on Linux.
    ln -s ${pname} $out/bin/orca-ide
  '';

  meta = {
    description = "Orca desktop IDE for running multiple coding agents side by side (official AppImage)";
    homepage = "https://github.com/stablyai/orca";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
