# GitHub Copilot desktop app, wrapped from the official upstream AppImage.
#
# GitHub publishes an official Linux AppImage; this wraps it using the same
# AppImage approach as Obsidian (see pkgs/obsidian.nix).
#
# Consumed two ways:
#   1. As a flake output:  nix build .#github-copilot-app
#      The app is proprietary and the flake's `packages` output does not set
#      allowUnfree, so building it from the flake needs the escape hatch:
#        NIXPKGS_ALLOW_UNFREE=1 nix build .#github-copilot-app --impure
#   2. Via the `additions` overlay:  pkgs.github-copilot-app (installed in
#      home-manager/ai.nix).  The home-manager nixpkgs config already sets
#      allowUnfree, so no flag there.
#
# Updating: bump `version`, then
#   nix store prefetch-file --json https://github.com/github/app/releases/download/v<version>/GitHub-Copilot-linux-x64.AppImage
# and paste the printed `hash` (SRI) below. No flake input changes are involved.
# Only the x86_64 AppImage is pinned; other architectures are unsupported here.

{ lib
, appimageTools
, fetchurl
}:

let
  pname = "github-copilot-app";
  version = "1.5.0";

  src = fetchurl {
    url = "https://github.com/github/app/releases/download/v${version}/GitHub-Copilot-linux-x64.AppImage";
    hash = "sha256-sq+RFAsMjL5cSAfwcG3KGHVpvJ2YW5PnkeHEoFf7t+c=";
  };

  # Extracted separately so upstream's own launcher entry and icon theme can be
  # reused instead of maintained by hand.
  extracted = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # The app's cached Git HTTPS helper requires CURL_OPENSSL_4. Replace the
  # AppImage FHS default's curlWithGnuTls only for this application.
  multiPkgs = fhsPkgs:
    lib.filter (pkg: lib.getName pkg != "curl")
      (appimageTools.defaultFhsEnvArgs.multiPkgs fhsPkgs)
    ++ [ fhsPkgs.curl ];

  extraInstallCommands = ''
    # Icon theme and MIME definitions shipped inside the AppImage. Desktop
    # entries are skipped here; they are copied below so they can be retargeted.
    (
      mkdir -p $out/share
      cd ${extracted}/usr
      find share -mindepth 1 -type d -exec mkdir -p $out/{} \;
      find share -mindepth 1 \( -type f -o -type l \) \
        -not -path 'share/applications/*' -exec ln -s $PWD/{} $out/{} \;
    )

    # Upstream launches its inner `github` binary; point the entry at the
    # wrapper binary that wrapType2 installs in $out/bin instead. Entries are
    # copied rather than symlinked so they stay writable, and the loop quotes
    # paths because upstream ships "GitHub Copilot.desktop" with a space.
    mkdir -p $out/share/applications
    shopt -s nullglob
    found=
    for entry in ${extracted}/*.desktop ${extracted}/usr/share/applications/*.desktop; do
      found=1
      dest="$out/share/applications/$(basename "$entry")"
      install -Dm644 "$entry" "$dest"
      substituteInPlace "$dest" --replace-fail 'Exec=github' "Exec=${pname}"
    done
    test -n "$found" \
      || { echo "upstream AppImage ships no desktop entry" >&2; exit 1; }
  '';

  meta = {
    description = "GitHub Copilot desktop app (official AppImage)";
    homepage = "https://github.com/features/copilot";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
