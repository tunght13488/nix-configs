# Pinned Herdr App release; the desktop app and phone share herdr-core terminals/spaces.
# Consumers: pkgs/default.nix and home-manager/home.nix.
{ lib
, stdenv
, stdenvNoCC
, fetchurl
, autoPatchelfHook
, makeWrapper
, fontconfig
, freetype
, libGL
, libxcb
, libxkbcommon
, vulkan-loader
, wayland
, zlib
, herdrCore
}:

let
  version = "0.1.16";
  target = {
    "x86_64-linux" = {
      arch = "x86_64";
      hash = "sha256-KC0mMhlrI4IGz+Zr+2HA+vKZyhyRhDvQdlIbvjZXEhY=";
    };
    "aarch64-linux" = {
      arch = "aarch64";
      hash = "sha256-7+708XWbDokA8gXCwisUKHoRL4dEBlObTqGzviS3NjE=";
    };
  }.${stdenv.hostPlatform.system};

  src = fetchurl {
    url = "https://releases.herdr.dev/app/${version}/herdr-app-linux-${target.arch}.tar.gz";
    inherit (target) hash;
  };

  agentGuide = fetchurl {
    url = "https://raw.githubusercontent.com/herdrdev/herdr-app/v${version}/defaults/AGENTS.md";
    hash = "sha256-HiO6lu9E+1iMHf2DkvXLIyvI4Q02dys4YzGRic4zwsU=";
  };
in
assert lib.versionAtLeast herdrCore.version "0.1.11";
stdenvNoCC.mkDerivation {
  pname = "herdr-app";
  inherit version src;

  sourceRoot = "herdr-app";
  dontBuild = true;

  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];
  buildInputs = [
    fontconfig
    freetype
    libGL
    libxcb
    libxkbcommon
    stdenv.cc.cc.lib
    vulkan-loader
    wayland
    zlib
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 herdr-app "$out/bin/herdr-app"
    wrapProgram "$out/bin/herdr-app" \
      --prefix PATH : "${herdrCore}/bin" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ wayland libxkbcommon libxcb vulkan-loader ]}"
    install -Dm644 herdr-app.svg \
      "$out/share/icons/hicolor/scalable/apps/herdr-app.svg"
    install -Dm644 LICENSE "$out/share/licenses/herdr-app/LICENSE"
    install -Dm644 THIRD-PARTY-NOTICES \
      "$out/share/licenses/herdr-app/THIRD-PARTY-NOTICES"
    mkdir -p "$out/share/applications"
    cat > "$out/share/applications/herdr-app.desktop" <<EOF
    [Desktop Entry]
    Name=Herdr
    Exec=$out/bin/herdr-app
    Icon=herdr-app
    Type=Application
    Terminal=false
    Categories=Development;
    StartupWMClass=herdr-app
    EOF
    runHook postInstall
  '';

  # Keep the icon out of bin so the release self-updater doesn't treat the Nix store as an install root.
  passthru = { inherit agentGuide; };

  meta = {
    description = "Desktop app for terminals and coding agents, backed by herdr-core";
    homepage = "https://herdr.dev/";
    license = lib.licenses.asl20;
    mainProgram = "herdr-app";
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
