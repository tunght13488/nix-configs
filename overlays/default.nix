# This file defines overlays
{ inputs, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs // {
    openspecAgentFiles = final.callPackage ../pkgs/openspec-agent-files.nix { };
  };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://wiki.nixos.org/wiki/Overlays
  modifications = final: prev: {
    # docker_28 is marked insecure on nixos-25.11 (unmaintained since Nov 2025);
    # alias pkgs.docker to docker_29 so virtualisation.docker and
    # virtualisation.docker.rootless both pull a maintained build.
    docker = prev.docker_29;

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
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };

  # PHP versions from https://github.com/fossar/nix-phps
  # Provides pkgs.php81, pkgs.php82, pkgs.php83, etc.
  phps = inputs.phps.overlays.default;
}
