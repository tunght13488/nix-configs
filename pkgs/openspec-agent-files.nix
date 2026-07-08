# OpenSpec agent integration files (skills, prompts, commands) for Pi and OpenCode.
#
# Fetches the OpenSpec source at a pinned version and generates the agent
# integration files at build time using the upstream adapter/template modules.
# Replace the previous approach where pre-generated files were checked into
# pkgs/openspec-agent-files/.
#
# Consumed by home-manager/openspec.nix to link individual files into
# global agent config directories (~/.pi/agent/ and ~/.config/opencode/).

{ stdenv, fetchFromGitHub, esbuild, nodejs }:

let
  version = "1.5.0";
  src = fetchFromGitHub {
    owner = "Fission-AI";
    repo = "OpenSpec";
    rev = "v${version}";
    hash = "sha256-CR82VPMGUhZB0yl2aT+ou60n5Bj2cjgG9Rt7A3dXsVQ=";
  };
in
stdenv.mkDerivation rec {
  name = "openspec-agent-files-${version}";
  inherit src version;

  nativeBuildInputs = [ esbuild nodejs ];

  OPENSPEC_VERSION = version;

  buildPhase = ''
    runHook preBuild

    # Copy build script into source tree so its relative imports resolve
    cp ${./generate-agent-files.mjs} generate-agent-files.mjs

    # Bundle adapters and templates into a single executable
    esbuild generate-agent-files.mjs \
      --bundle --platform=node --format=esm \
      --outfile=$TMPDIR/agent-files.mjs

    # Generate all .pi/ and .opencode/ files in the source directory
    node $TMPDIR/agent-files.mjs

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r .pi $out/
    cp -r .opencode $out/

    runHook postInstall
  '';
}
