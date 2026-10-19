# Obsidian, wrapped from the official upstream AppImage.
#
# The nixpkgs `obsidian` package builds from a source tarball and lags
# upstream; upstream only ships Linux releases as an AppImage, so this wraps
# that binary directly and pins it.
#
# Consumed two ways:
#   1. As a flake output:  nix build .#obsidian
#      Obsidian is unfree and the flake's `packages` output does not set
#      allowUnfree, so building it from the flake needs the escape hatch:
#        NIXPKGS_ALLOW_UNFREE=1 nix build .#obsidian --impure
#   2. Via the `additions` overlay:  pkgs.obsidian (installed in home-manager/home.nix)
#      The home-manager nixpkgs config already sets allowUnfree, so no flag here.
#
# Updating: bump `version`, then
#   nix-prefetch-url https://github.com/obsidianmd/obsidian-releases/releases/download/v<version>/Obsidian-<version>.AppImage
#   nix hash convert --hash-algo sha256 --to sri <printed-base32-hash>
# and paste the SRI hash below. No flake input changes are involved.

{ lib, appimageTools, fetchurl }:

let
  pname = "obsidian";
  version = "1.14.4";

  src = fetchurl {
    url = "https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/Obsidian-${version}.AppImage";
    hash = "sha256-Y2Ldvu7rt7vMtI+uAJVyzyKE75L1yRnBMyq6SN5v/qo=";
  };

  # Extracted separately so upstream's desktop file and icon theme can be
  # reused instead of maintained by hand.
  extracted = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    # Icon theme and MIME definitions shipped inside the AppImage.
    (
      mkdir -p $out/share
      cd ${extracted}/usr
      find share -mindepth 1 -type d -exec mkdir -p $out/{} \;
      find share -mindepth 1 -type f,l -exec ln -s $PWD/{} $out/{} \;
    )

    # Upstream ships the desktop file at the AppImage root with Exec=AppRun;
    # retarget it at the wrapper binary that wrapType2 installs in $out/bin.
    install -Dm444 ${extracted}/md.obsidian.Obsidian.desktop \
      $out/share/applications/md.obsidian.Obsidian.desktop
    substituteInPlace $out/share/applications/md.obsidian.Obsidian.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=${pname}'
  '';

  meta = {
    description = "Knowledge base and note-taking application (official AppImage)";
    homepage = "https://obsidian.md";
    license = lib.licenses.obsidian;
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
