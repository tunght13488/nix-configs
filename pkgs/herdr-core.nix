# herdr-core (`hc`): terminals for coding agents that stay alive after you leave.
# Consumers: pkgs/default.nix (flake package `nix build .#herdr-core`) and the
# `additions` overlay (`pkgs.herdr-core`), which home-manager installs.
#
# Upstream has no flake.nix, and a flake `github:` input does not fetch git
# submodules, so vendor/ghostty (needed by crates/ghostty-vt/build.rs) is only
# available through fetchFromGitHub's fetchSubmodules.
#
# To update:
#   1. Bump `version` to the new tag and `rev` to its commit:
#        git ls-remote https://github.com/herdrdev/herdr-core refs/tags/v<version>
#   2. Set both hashes to lib.fakeHash and run `nix build .#herdr-core` twice,
#      copying each reported "got:" value in (src hash first, then zigDeps).
#   3. Run `nix build .#herdr-core && result/bin/hc --version`.

{ lib
, fetchFromGitHub
, rustPlatform
, zig_0_16
, zstd
,
}:

let
  version = "0.1.21";

  src = fetchFromGitHub {
    owner = "herdrdev";
    repo = "herdr-core";
    rev = "1b0393f80c35b1dae34f37934d33d0144a8fc8d7"; # v0.1.21
    hash = "sha256-sKO8RNlz8lEc0ZUED/VKqIxPmzGxEfMMJjj9V0H0CM4=";
    fetchSubmodules = true;
  };

  # Ghostty's Zig package cache, so `zig build` in ghostty-vt/build.rs needs no
  # network. fetchAll pulls the lazy dependencies too: the build does not know
  # which of them `-Demit-lib-vt` reaches.
  zigDeps = zig_0_16.fetchDeps {
    pname = "herdr-core-ghostty-zig-cache";
    inherit version;
    src = "${src}/vendor/ghostty";
    fetchAll = true;
    hash = "sha256-G9xbZ/pyQTDIfzG0h++i70a45zpwyYpZMBZfAnoOQw0=";
  };
in
rustPlatform.buildRustPackage {
  pname = "herdr-core";
  inherit version src;

  cargoLock.lockFile = "${src}/Cargo.lock";

  # Not in nativeBuildInputs: zig's setup hook replaces buildPhase with
  # `zig build` in the source root. build.rs only needs the binary via ZIG.
  nativeBuildInputs = [ zstd ];
  env.ZIG = lib.getExe zig_0_16;

  preBuild = ''
    # zigDeps is the read-only `p` directory; Zig also writes compiled
    # dependency artifacts next to it, so seed a writable global cache.
    export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-global-cache"
    mkdir -p "$ZIG_GLOBAL_CACHE_DIR"
    cp -r ${zigDeps} "$ZIG_GLOBAL_CACHE_DIR/p"
    chmod -R u+w "$ZIG_GLOBAL_CACHE_DIR"
  '';

  # Upstream installs `herdr-core` and symlinks `hc` beside it.
  postInstall = ''
    ln -s herdr-core $out/bin/hc
  '';

  # Upstream CI runs the Rust test suite; building is what validates packaging.
  doCheck = false;

  meta = {
    description = "Terminals for coding agents that stay alive after you leave";
    homepage = "https://github.com/herdrdev/herdr-core";
    license = lib.licenses.asl20;
    mainProgram = "herdr-core";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
