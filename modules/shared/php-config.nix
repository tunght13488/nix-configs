# modules/shared/php-config.nix — Centralized PHP configuration options.
#
# Import this module in both NixOS and home-manager to get typed options
# under `phpConfig.*`.  The module computes derivations and scan-dir strings
# that consumers (nixos/php-fpm.nix, home-manager/php.nix) read from
# `config.phpConfig._lib.versions.<ver>.*`.
#
# Default values come from pkgs/php-config.nix (also used by devShells directly).
#
# Usage example (in any consumer that imports this module):
#   config.phpConfig._lib.versions.php81.fpmIniScanDir
#   config.phpConfig._lib.versions.php83.cliIniScanDir
#   config.phpConfig._lib.versions.php83.versionedPkg
{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.phpConfig;
  defaults = import ../../pkgs/php-config.nix;

  versionSubmodule = lib.types.submodule {
    options = {
      common = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "INI settings applied to both FPM and CLI for this version.";
        example = "opcache.enable=1";
      };
      fpm = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "INI settings applied only to FPM for this version.";
        example = "opcache.jit=tracing";
      };
      cli = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "INI settings applied only to CLI for this version.";
        example = "memory_limit = -1";
      };
    };
  };
in
{
  options.phpConfig = {
    common = lib.mkOption {
      type = lib.types.lines;
      default = defaults.common;
      description = "INI settings applied to every PHP version (both FPM and CLI).";
      example = "display_errors = On";
    };

    fpm = lib.mkOption {
      type = lib.types.lines;
      default = defaults.fpm;
      description = "INI settings applied to every PHP version, FPM only.";
      example = "memory_limit = 128M";
    };

    cli = lib.mkOption {
      type = lib.types.lines;
      default = defaults.cli;
      description = "INI settings applied to every PHP version, CLI only.";
      example = "memory_limit = 1G";
    };

    versions = lib.mkOption {
      type = lib.types.attrsOf versionSubmodule;
      default = defaults.versions;
      description = ''
        Per-version PHP configuration.  Keys are version identifiers matching
        nixpkgs package names (e.g. "php81", "php82", "php83").
      '';
      example = {
        php81 = {
          common = "";
          fpm = "";
          cli = "";
        };
        php83 = {
          common = "";
          fpm = "opcache.jit=tracing";
          cli = "";
        };
      };
    };

    _lib = lib.mkOption {
      type = lib.types.unspecified;
      readOnly = true;
      internal = true;
      description = "Computed PHP derivations and helpers (read-only).";
    };
  };

  config.phpConfig._lib = import ../../pkgs/php-lib.nix {
    inherit pkgs;
    config = {
      common = cfg.common;
      fpm = cfg.fpm;
      cli = cfg.cli;
      versions = cfg.versions;
    };
  };
}
