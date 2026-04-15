# pkgs/php-lib.nix — PHP INI derivation builders.
#
# Pure function: takes { pkgs, config } where config matches the shape of
# phpConfig options (see modules/shared/php-config.nix) and returns
# derivations and helper functions.
#
# Merge order for FPM: common → fpm → versions.<ver>.common → versions.<ver>.fpm
# Merge order for CLI: common → cli → versions.<ver>.common → versions.<ver>.cli
#
# Consumed by:
#   - modules/shared/php-config.nix (NixOS and home-manager module)
#   - flake.nix devShells (directly, with default config)
{ pkgs, config }:
let
  # Build a scan-dir derivation from an INI content string.
  mkIniDir =
    name: content:
    pkgs.writeTextFile {
      inherit name;
      text = content;
      destination = "/custom.ini";
    };

  # Merge INI layers into a single string.
  # FPM: common → fpm → version.common → version.fpm
  # CLI: common → cli → version.common → version.cli
  mergeFpmIni =
    versionCfg:
    builtins.concatStringsSep "\n" (
      builtins.filter (s: s != "") [
        config.common
        config.fpm
        versionCfg.common
        versionCfg.fpm
      ]
    );

  mergeCliIni =
    versionCfg:
    builtins.concatStringsSep "\n" (
      builtins.filter (s: s != "") [
        config.common
        config.cli
        versionCfg.common
        versionCfg.cli
      ]
    );

  # Build the PHP_INI_SCAN_DIR value for a given php package and merged INI string.
  # Layout: php/lib (extension= lines from nixpkgs) : merged custom.ini
  mkIniScanDir =
    php: mergedIniContent:
    let
      iniDir = mkIniDir "php-custom-ini" mergedIniContent;
    in
    "${php}/lib:${iniDir}";

  # Per-version computed helpers.
  # `name` is the nixpkgs attribute (e.g. "php81"), `versionCfg` has common/fpm/cli.
  mkVersionHelpers =
    name: versionCfg:
    let
      # "php81" → "81"
      ver = builtins.replaceStrings [ "php" ] [ "" ] name;
      phpPkg = pkgs.${name};
      fpmIni = mergeFpmIni versionCfg;
      cliIni = mergeCliIni versionCfg;
      fpmIniScanDir = mkIniScanDir phpPkg fpmIni;
      cliIniScanDir = mkIniScanDir phpPkg cliIni;
    in
    {
      inherit
        phpPkg
        fpmIni
        cliIni
        fpmIniScanDir
        cliIniScanDir
        ;

      # Versioned wrapper scripts (php81, php81-fpm, php81ize, …) using CLI INI.
      versionedPkg = pkgs.runCommand "php${ver}-versioned" { } ''
        mkdir -p $out/bin
        for src in ${phpPkg}/bin/php ${phpPkg}/bin/php-fpm ${phpPkg}/bin/php-cgi ${phpPkg}/bin/phpdbg ${phpPkg}/bin/phpize ${phpPkg}/bin/php-config; do
          [ -e "$src" ] || continue
          base=$(basename "$src")
          versioned=$(echo "$base" | sed "s/^php/php${ver}/")
          printf '#!/bin/sh\nexport PHP_INI_SCAN_DIR="%s"\nexec "%s" "$@"\n' \
            "${cliIniScanDir}" "$src" > "$out/bin/$versioned"
          chmod +x "$out/bin/$versioned"
        done
      '';

      # Default (non-versioned) wrappers using CLI INI.
      defaultPkg = pkgs.runCommand "php-default-with-ini" { } ''
        mkdir -p $out/bin
        for src in ${phpPkg}/bin/php ${phpPkg}/bin/php-fpm ${phpPkg}/bin/php-cgi ${phpPkg}/bin/phpdbg ${phpPkg}/bin/phpize ${phpPkg}/bin/php-config; do
          [ -e "$src" ] || continue
          name=$(basename "$src")
          printf '#!/bin/sh\nexport PHP_INI_SCAN_DIR="%s"\nexec "%s" "$@"\n' \
            "${cliIniScanDir}" "$src" > "$out/bin/$name"
          chmod +x "$out/bin/$name"
        done
      '';

      # Composer wrapper using CLI INI.
      composerPkg = pkgs.writeShellScriptBin "composer" ''
        export PHP_INI_SCAN_DIR="${cliIniScanDir}"
        exec ${phpPkg.packages.composer}/bin/composer "$@"
      '';
    };

  versions = builtins.mapAttrs mkVersionHelpers config.versions;
in
{
  inherit
    mkIniDir
    mkIniScanDir
    mergeFpmIni
    mergeCliIni
    versions
    ;
}
