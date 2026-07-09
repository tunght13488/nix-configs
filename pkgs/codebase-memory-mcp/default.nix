# Nix package for codebase-memory-mcp.
#
# Fetches the pre-built static portable binary from GitHub releases.
# The `-portable` variant is a fully static binary (no glibc dependency)
# with embedded SQLite, tree-sitter grammars, and nomic-embed-code embeddings.
#
# The package also includes the pi skill file for CLI-based code discovery.

{ lib, stdenv, fetchurl, yamllint, ... }:

let
  version = "0.9.0";
  system = stdenv.hostPlatform.system;
  pname = "codebase-memory-mcp";

  # Map Nix system to GitHub release asset naming
  assetMap = {
    x86_64-linux = {
      arch = "linux-amd64";
      ext = "tar.gz";
    };
    aarch64-linux = {
      arch = "linux-arm64";
      ext = "tar.gz";
    };
    x86_64-darwin = {
      arch = "darwin-amd64";
      ext = "tar.gz";
    };
    aarch64-darwin = {
      arch = "darwin-arm64";
      ext = "tar.gz";
    };
  };

  asset = assetMap.${system} or (throw "Unsupported system: ${system}");
  # Use the portable variant on Linux (fully static); macOS/Windows have no portable variant
  portable = if lib.hasPrefix "linux" asset.arch then "-portable" else "";
  ext = asset.ext;

  archiveName = "${pname}-${asset.arch}${portable}.${ext}";

  src = fetchurl {
    url = "https://github.com/DeusData/${pname}/releases/download/v${version}/${archiveName}";
    hash = "sha256-hFnVydFFfyyC3j3jB//HZB7Lui3eiTQnvh5i7KjvmyU=";
  };
in
stdenv.mkDerivation {
  inherit pname version src;

  sourceRoot = ".";

  phases = [ "unpackPhase" "installPhase" "checkPhase" ];

  installPhase = ''
    mkdir -p $out/bin $out/share/pi/skills/codebase-memory
    cp codebase-memory-mcp $out/bin/
    chmod 755 $out/bin/codebase-memory-mcp
    cp ${./skill.md} $out/share/pi/skills/codebase-memory/SKILL.md
  '';

  doCheck = true;

  checkInputs = [ yamllint ];

  checkPhase = ''
    runHook preCheck
    skill="$out/share/pi/skills/codebase-memory/SKILL.md"
    sed -n '/^---$/,/^---$/p' "$skill" | yamllint --strict -d '{rules: {line-length: disable}}' -
    runHook postCheck
  '';

  meta = with lib; {
    description = "High-performance code intelligence MCP server with knowledge graphs";
    homepage = "https://github.com/DeusData/codebase-memory-mcp";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    mainProgram = "codebase-memory-mcp";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
