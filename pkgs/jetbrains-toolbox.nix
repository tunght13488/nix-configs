# JetBrains Toolbox, pinned in-repo.
#
# nixpkgs' own package (nixpkgs-unstable 3.6.2.85969) fetches from
# download-cdn.jetbrains.com, which now answers 404 for old releases; JetBrains
# serves them from download.jetbrains.com instead, and nixpkgs only switched
# hosts after the revision pinned in flake.lock. nixpkgs master carries 3.9.0,
# nixos-unstable still 3.8.1, so the version and host are pinned here until the
# unstable input catches up (then delete this file and its overlay entry).
#
# Wired in overlays/default.nix as `unstable.jetbrains-toolbox`; that is what
# home-manager/home.nix installs, so no consumer changes when this bumps.
#
# Updating: set `version`, then take the hash from nixpkgs (it must be the
# fetchzip tree hash, which differs from the tarball's own .sha256) or compute it:
#   nix store prefetch-file --hash-type sha256 --unpack \
#     https://download.jetbrains.com/toolbox/jetbrains-toolbox-<version>.tar.gz
# No flake input changes are involved.

{ lib
, stdenvNoCC
, buildFHSEnv
, fetchzip
, appimageTools
}:

let
  pname = "jetbrains-toolbox";
  version = "3.9.0.88839";

  src = fetchzip {
    url = "https://download.jetbrains.com/toolbox/${pname}-${version}.tar.gz";
    hash = "sha256-Nqov5++wuLy4r08N6inyBmdr9eTdQknrc1AFf0jywTs=";
  };

  meta = {
    description = "JetBrains Toolbox";
    homepage = "https://www.jetbrains.com/toolbox-app";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [
      ners
      fabiob
    ];
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
in
assert lib.assertMsg stdenvNoCC.hostPlatform.isx86_64
  "${pname} is pinned for x86_64 only in this repository";
buildFHSEnv {
  inherit pname version meta;

  passthru = { inherit src; };

  multiPkgs =
    pkgs:
      with pkgs;
      [
        icu
        libappindicator-gtk3
      ]
      ++ appimageTools.defaultFhsEnvArgs.multiPkgs pkgs;

  runScript = "${src}/bin/jetbrains-toolbox --update-failed";

  extraInstallCommands = ''
    install -Dm0644 ${src}/bin/jetbrains-toolbox.desktop -t $out/share/applications
    install -Dm0644 ${src}/bin/toolbox-tray-color.png $out/share/icons/hicolor/32x32/apps/jetbrains-toolbox.png
  '';
}
