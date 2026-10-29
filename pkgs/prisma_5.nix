# pkgs/prisma_5.nix — Prisma CLI 5.17.0
#
# Named after nixpkgs' prisma_6 / prisma_7. It exists because LiteLLM's Python
# Prisma client (prisma-client-py 0.15) only generates and runs against Prisma
# 5.17.0 engines, which nixpkgs does not package.
#
# The published CLI is bundled JavaScript; only its runtime dependencies are
# installed. Engines come from pkgs/prisma-engines_5.nix instead of Prisma's
# network postinstall, so nothing is downloaded at build or first start.
#
# Consumers: pkgs/prisma_5-litellm_schema.nix, nixos/litellm.nix.
#
# Updating: bump `version`, `enginesVersion` in prisma-engines_5.nix, and
# `npmDepsHash` here, then rebuild.
{ lib
, stdenv
, cacert
, nodejs
, makeWrapper
, prisma-engines_5
,
}:

let
  version = "5.17.0";

  # The network step, isolated as a fixed-output derivation: npm needs the
  # internet, and the npm registry is immutable, so the installed tree is
  # reproducible.
  nodeModules = stdenv.mkDerivation {
    pname = "prisma_5-node-modules";
    inherit version;

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-A7SfaS3HXKBGGcFSJH4LgL91IYAR3h4Y/93V/YTCkcw=";

    nativeBuildInputs = [
      nodejs
      cacert
    ];

    dontUnpack = true;

    buildPhase = ''
      runHook preBuild

      export HOME=$TMPDIR/home
      mkdir -p "$HOME"

      # npm needs a CA bundle, and build sandboxes have no /etc/ssl.
      export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt
      export NODE_EXTRA_CA_CERTS=$SSL_CERT_FILE

      npm install \
        --ignore-scripts \
        --no-audit \
        --no-fund \
        --no-package-lock \
        --prefix $TMPDIR/npm \
        prisma@${version}

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/node_modules
      cp -r $TMPDIR/npm/node_modules/. $out/lib/node_modules/
      runHook postInstall
    '';
  };
in
stdenv.mkDerivation {
  pname = "prisma_5";
  inherit version;

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib
    cp -r ${nodeModules}/lib/node_modules $out/lib/node_modules

    makeWrapper ${nodejs}/bin/node $out/bin/prisma \
      --add-flags $out/lib/node_modules/prisma/build/index.js \
      --set PRISMA_QUERY_ENGINE_BINARY ${lib.getExe' prisma-engines_5 "query-engine"} \
      --set PRISMA_SCHEMA_ENGINE_BINARY ${lib.getExe' prisma-engines_5 "schema-engine"} \
      --set PRISMA_QUERY_ENGINE_LIBRARY ${prisma-engines_5}/lib/libquery_engine.so.node \
      --set PRISMA_HIDE_UPDATE_MESSAGE true \
      --set CHECKPOINT_DISABLE 1 \
      --prefix NODE_PATH : $out/lib/node_modules

    runHook postInstall
  '';

  passthru = { engines = prisma-engines_5; };

  meta = {
    description = "Prisma CLI ${version} (pinned to the engine version prisma-client-py expects)";
    homepage = "https://github.com/prisma/prisma";
    license = lib.licenses.asl20;
    mainProgram = "prisma";
    platforms = lib.platforms.linux;
  };
}
