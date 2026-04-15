# pkgs/php-config.nix — Default PHP INI configuration values.
#
# Single source of truth for PHP settings.  Imported by:
#   - modules/shared/php-config.nix (as option defaults)
#   - flake.nix devShells (directly, since devShells are outside the module system)
#
# Merge order for FPM: common → fpm → versions.<ver>.common → versions.<ver>.fpm
# Merge order for CLI: common → cli → versions.<ver>.common → versions.<ver>.cli
{
  # Applied to every PHP version, both FPM and CLI.
  common = "";

  # Applied to every PHP version, FPM only.
  fpm = ''
    memory_limit = 128M
  '';

  # Applied to every PHP version, CLI only.
  cli = ''
    memory_limit = 1G
  '';

  # Per-version settings.  Keys match nixpkgs PHP package attribute names.
  # Each version has: common (both FPM+CLI), fpm (FPM only), cli (CLI only).
  versions = {
    php81 = {
      common = "";
      fpm = "";
      cli = "";
    };
    php82 = {
      common = "";
      fpm = "";
      cli = "";
    };
    php83 = {
      common = "";
      fpm = "";
      cli = "";
    };
  };
}
