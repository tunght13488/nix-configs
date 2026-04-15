# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
#
# Packages here are exposed two ways:
#   1. As flake outputs:  nix build .#<name>
#   2. Via the `additions` overlay:  pkgs.<name>
pkgs: {
  # example = pkgs.callPackage ./example { };

  # PHP INI derivation builders.  Takes a config attrset matching the shape
  # of the phpConfig module options and returns per-version helpers.
  # Used directly by devShells (outside the module system).
  phpLib = config: import ./php-lib.nix { inherit pkgs config; };
}
