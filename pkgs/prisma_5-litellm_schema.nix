# pkgs/prisma_5-litellm_schema.nix — prisma-client-py with a generated LiteLLM client
#
# Why this exists: prisma-client-py ships *without* a generated client. LiteLLM
# imports `prisma.Prisma` at startup, which raises "The Client hasn't been
# generated yet" unless `prisma generate` has run against LiteLLM's schema.
# Upstream LiteLLM's container entrypoint does exactly that at boot, which
# cannot work on NixOS because site-packages lives in the read-only store.
#
# So the client is generated here, at build time: the Python package is copied
# to a writable output and `prisma generate` points its output at that copy (the
# generator writes next to the imported `prisma` package, hence PYTHONPATH).
#
# Consumers: overlays/default.nix overrides `pkgs.litellm`'s `prisma` argument
# with this package.
{ lib
, stdenv
, python3
, prisma_5
, litellmSchema
,
}:

stdenv.mkDerivation {
  pname = "prisma_5-litellm_schema";
  inherit (python3.pkgs.prisma) version;

  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [
    python3
    prisma_5
  ];

  # Generation only parses the schema; the datasource URL is never dialled.
  DATABASE_URL = "postgresql://litellm@127.0.0.1:5432/litellm";

  # The build sandbox has no libssl for Prisma to sniff, so pin the binary
  # target; the engines themselves come from pkgs/prisma-engines_5.nix (wired
  # up by pkgs/prisma_5.nix) and are never downloaded here.
  PRISMA_CLI_BINARY_TARGETS = "debian-openssl-3.0.x";

  # Skip the CLI's Node-API engine download: the Python generator takes the
  # engine paths from the environment, and downloading is impossible in a
  # sandbox anyway.
  PRISMA_GENERATE_NO_ENGINE = "true";
  PRISMA_CLI_QUERY_ENGINE_TYPE = "binary";

  installPhase = ''
    runHook preInstall

    # A writable copy of the Python package: the generator writes into it.
    mkdir -p $out
    cp -r ${python3.pkgs.prisma}/. $out/
    chmod -R u+w $out

    # Make `import prisma` resolve to the copy so its __file__ points here; the
    # generator entry point must also be on PATH for the CLI to invoke it.
    export PYTHONPATH=$out/${python3.sitePackages}
    export PATH=${prisma_5}/bin:${python3.pkgs.prisma}/bin:$PATH

    prisma generate --schema ${litellmSchema}

    # prisma-client-py installs a `prisma` console script that bootstraps its own
    # npm/nodeenv cache on first use. LiteLLM's launcher prepends every
    # dependency's bin/ to PATH, so that script would shadow pkgs/prisma_5 and
    # then fail on the read-only store (or on HOME=/var/lib for a DynamicUser).
    # Runtime only needs the library, so drop both console scripts; the build
    # above already used the pristine package's generator from PATH.
    rm -f $out/bin/prisma $out/bin/prisma-client-py
    rmdir $out/bin 2>/dev/null || true

    # Fail loudly rather than shipping a package without a usable client.
    test -f $out/${python3.sitePackages}/prisma/client.py
    test -f $out/${python3.sitePackages}/prisma/models.py

    runHook postInstall
  '';

  meta = {
    description = "Python Prisma client generated from LiteLLM's Prisma schema (Prisma 5.17.0)";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
