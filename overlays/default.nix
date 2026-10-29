# This file defines overlays
{ inputs, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs // {
    herdrAgentFiles = final.callPackage ../pkgs/herdr-agent-files.nix {
      herdrSrc = inputs.herdr.outPath;
    };
  };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://wiki.nixos.org/wiki/Overlays
  modifications = final: prev: {
    # docker_28 is marked insecure on nixos-25.11 (unmaintained since Nov 2025);
    # alias pkgs.docker to docker_29 so virtualisation.docker and
    # virtualisation.docker.rootless both pull a maintained build.
    docker = prev.docker_29;

    # LiteLLM's database support cannot work from the plain nixpkgs package:
    #
    #   1. prisma-client-py ships without a generated client, and LiteLLM imports
    #      `prisma.Prisma` at startup. Upstream generates it at container boot,
    #      which is impossible here because site-packages is read-only. Generate
    #      it at build time against LiteLLM's own schema instead.
    #   2. Its default schema bootstrap path runs `prisma migrate deploy` through
    #      litellm-proxy-extras, which is not packaged in nixpkgs ("FIXME package
    #      litellm-proxy-extras"), so setup always failed. `prisma db push` needs
    #      no migrations package and is idempotent.
    #
    # 5.17.0 is pinned because prisma-client-py 0.15 refuses any other engine
    # version; see pkgs/prisma-engines_5.nix / pkgs/prisma_5.nix.
    #
    # Version comes from nixpkgs-unstable (`pkgs.unstable`), on its Python 3.13
    # package set: unstable's default is 3.14, while the pinned Prisma runtime
    # (pkgs/prisma_5*.nix) is built for 3.13. release-26.05 ships LiteLLM 1.86.0,
    # unstable ships a newer one with the GitHub Copilot OAuth fixes. Everything
    # else — the
    # generated prisma client and the db-push patch — is ours, so the newer
    # package only contributes sources and dependency metadata.
    litellm =
      let
        litellmPy = final.unstable.python313Packages.litellm.override {
          # Generated against the same schema this litellm is built from.
          prisma = final.prisma_5-litellm_schema;
        };

        litellmPyPatched = litellmPy.overridePythonAttrs (oldAttrs: {
          postPatch = (oldAttrs.postPatch or "") + ''
            substituteInPlace litellm/proxy/proxy_cli.py \
              --replace-fail "use_migrate=not use_prisma_db_push" "use_migrate=False"
          '';
        });
      in
      # Mirrors pkgs/by-name/li/litellm/package.nix, which enables the proxy
        # extras (that is what pulls the overridden prisma client in).
      final.unstable.python313Packages.toPythonApplication (
        litellmPyPatched.overridePythonAttrs (oldAttrs: {
          dependencies =
            (oldAttrs.dependencies or [ ])
            ++ litellmPy.optional-dependencies.proxy
            ++ litellmPy.optional-dependencies.extra_proxy
            ++ litellmPy.optional-dependencies.proxy-runtime;
        })
      );

    # Enable OpenSSL in libzip so AES-256 zip encryption works.
    libzip = prev.libzip.override { withOpenssl = true; };

    # Compile PHP with zlib statically so IMAGETYPE_SWC is defined.
    # The constant is gated by #if (defined(HAVE_ZLIB) && !defined(COMPILE_DL_ZLIB))
    # in ext/standard/basic_functions_arginfo.h, so it only exists when zlib
    # is compiled into the core binary (not as a shared extension).
    # We also remove zlib from the extensions list to avoid building the
    # shared extension which conflicts with the static one.
    php83 = prev.php83.override (origArgs: {
      phpAttrsOverrides = attrs: {
        configureFlags = attrs.configureFlags ++ [
          "--with-zlib=${final.zlib.dev}"
          "--with-zip"
        ];
        buildInputs = attrs.buildInputs ++ [
          final.zlib
          final.libzip
        ];
      };
      extensions =
        { all, enabled, ... }:
        builtins.filter (ext: ext != all.zlib && ext != all.zip) (
          origArgs.extensions { inherit all enabled; }
        );
    });
    php82 = prev.php82.override (origArgs: {
      phpAttrsOverrides = attrs: {
        configureFlags = attrs.configureFlags ++ [
          "--with-zlib=${final.zlib.dev}"
          "--with-zip"
        ];
        buildInputs = attrs.buildInputs ++ [
          final.zlib
          final.libzip
        ];
      };
      extensions =
        { all, enabled, ... }:
        builtins.filter (ext: ext != all.zlib && ext != all.zip) (
          origArgs.extensions { inherit all enabled; }
        );
    });
    php81 = prev.php81.override (origArgs: {
      phpAttrsOverrides = attrs: {
        configureFlags = attrs.configureFlags ++ [
          "--with-zlib=${final.zlib.dev}"
          "--with-zip"
        ];
        buildInputs = attrs.buildInputs ++ [
          final.zlib
          final.libzip
        ];
      };
      extensions =
        { all, enabled, ... }:
        builtins.filter (ext: ext != all.zlib && ext != all.zip) (
          origArgs.extensions { inherit all enabled; }
        );
    });
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = (import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    }).extend (final': prev': {
      # Override postman to latest upstream version because the nixpkgs
      # postman package lags at 11.94.0 (no 12.x PR on nixos-unstable).
      postman = prev'.postman.overrideAttrs (old: {
        version = "12.20.4";
        src = final'.fetchurl {
          name = "postman-12.20.4.tar.gz";
          url = "https://dl.pstmn.io/download/version/12.20.4/linux64";
          hash = "sha256-r8UNaNTtd1laBxBhEEnNBm/bKx6PuXNRIGQ86fw2zxw=";
        };
      });

      # Latest Toolbox (3.9.0) is only on nixpkgs master; the pinned unstable
      # revision still fetches 3.6.2 from a host that now 404s it. See
      # pkgs/jetbrains-toolbox.nix for the pin and its update steps.
      jetbrains-toolbox = final'.callPackage ../pkgs/jetbrains-toolbox.nix { };
    });
  };

  # MySQL 8.0 (EOL upstream, dropped from newer nixpkgs) for the local LAMP
  # stack. Imported from the pinned nixos-25.11 input; builds from the 25.11
  # binary cache.
  mysql80-packages = final: _prev: {
    mysql80 = (import inputs.nixpkgs-2511 { system = final.stdenv.hostPlatform.system; }).mysql80;
  };

  # PHP versions from https://github.com/fossar/nix-phps
  # Provides pkgs.php81, pkgs.php82, pkgs.php83, etc.
  phps = inputs.phps.overlays.default;
}
