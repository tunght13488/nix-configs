# pkgs/prisma-engines_5.nix — Prisma 5.17.0 query, schema and Node-API engines
#
# Split out from the CLI so the engines can be referenced on their own (the CLI
# wrapper and LiteLLM's Python Prisma client both need them), mirroring nixpkgs'
# prisma-engines_6 / prisma-engines_7 layout.
#
# 5.17.0 is pinned because prisma-client-py 0.15 refuses any other engine hash
# (`393aa359c9ad4a4bb28630fb5613f9c281cde053`), and nixpkgs only packages 6.x
# and 7.x.
#
# All three artifacts are needed: without PRISMA_QUERY_ENGINE_LIBRARY the CLI
# still tries to download the Node-API engine, which fails on a read-only store
# (and NixOS has no precompiled engines to fall back on).
#
# Consumers: pkgs/prisma_5.nix, nixos/litellm.nix.
{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, openssl
,
}:

let
  version = "5.17.0";

  # Engine commit shipped with Prisma 5.17.0; prisma-client-py validates the
  # query engine's `--version` against exactly this string.
  enginesVersion = "393aa359c9ad4a4bb28630fb5613f9c281cde053";

  engineHashes = {
    query-engine = "sha256-m8hX3r4NV2DFce5icQdiI9lL6YHCmiJAHeaB8/cOBn0=";
    schema-engine = "sha256-mK1DP9ZNouoettVlVTqaQzns8w8cIRsotpaQ9ZEmmkE=";
    "libquery_engine.so.node" = "sha256-El11c5vX/NuOq7VCg1W1vgD1QAQ+a8H1swJolHr6sb0=";
  };

  # Prisma publishes pristine glibc builds; autoPatchelfHook rewrites the
  # interpreter and OpenSSL rpath for NixOS. The Node-API library is published
  # under a target-independent name, unlike the downloadable CLI cache name
  # `libquery_engine-<target>.so.node`.
  fetchEngine =
    name:
    fetchurl {
      url = "https://binaries.prisma.sh/all_commits/${enginesVersion}/debian-openssl-3.0.x/${name}.gz";
      hash = engineHashes.${name};
    };
in
stdenv.mkDerivation {
  pname = "prisma-engines_5";
  inherit version;

  dontUnpack = true;

  nativeBuildInputs = [ autoPatchelfHook ];

  # libgcc_s comes from the compiler runtime, OpenSSL from the engines' TLS use.
  buildInputs = [
    openssl
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall

    # Published artifacts are gzipped single binaries.
    mkdir -p $out/bin $out/lib
    gzip -dc ${fetchEngine "query-engine"} > $out/bin/query-engine
    gzip -dc ${fetchEngine "schema-engine"} > $out/bin/schema-engine
    gzip -dc ${fetchEngine "libquery_engine.so.node"} > $out/lib/libquery_engine.so.node

    chmod 0755 $out/bin/query-engine $out/bin/schema-engine
    chmod 0644 $out/lib/libquery_engine.so.node

    runHook postInstall
  '';

  passthru = { inherit enginesVersion; };

  meta = {
    description = "Prisma ${version} query, schema and Node-API engines (pinned for prisma-client-py 0.15)";
    homepage = "https://github.com/prisma/prisma-engines";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
