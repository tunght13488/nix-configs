# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
#
# Packages here are exposed two ways:
#   1. As flake outputs:  nix build .#<name>
#   2. Via the `additions` overlay:  pkgs.<name>
pkgs: {
  # example = pkgs.callPackage ./example { };

  maven363 = pkgs.callPackage ./maven363.nix { };

  # Prisma 5.17.0, pinned for LiteLLM's Python Prisma client (prisma-client-py
  # 0.15 rejects any other engine version). Named after nixpkgs' prisma_6 /
  # prisma-engines_6 / prisma_7 / prisma-engines_7.
  prisma-engines_5 = pkgs.callPackage ./prisma-engines_5.nix { };
  prisma_5 = pkgs.callPackage ./prisma_5.nix { };

  # prisma-client-py with a client generated from LiteLLM's Prisma schema.
  # Consumers: overlays/default.nix (overrides `pkgs.litellm`'s prisma arg).
  # The schema comes from the litellm version actually being deployed, which is
  # nixpkgs-unstable's (see the `litellm` override in overlays/default.nix).
  # Built against unstable's Python 3.13 set: that is the interpreter LiteLLM
  # runs on (see overlays/default.nix), and mixing package sets would trip
  # nixpkgs' duplicate-dependency check.
  prisma_5-litellm_schema = pkgs.callPackage ./prisma_5-litellm_schema.nix {
    python3 = pkgs.unstable.python313;
    litellmSchema = "${pkgs.unstable.python313Packages.litellm.src}/litellm/proxy/schema.prisma";
  };

  # Official upstream AppImage, pinned.  See pkgs/obsidian.nix for update steps.
  obsidian = pkgs.callPackage ./obsidian.nix { };

  # PHP INI derivation builders.  Takes a config attrset matching the shape
  # of the phpConfig module options and returns per-version helpers.
  # Used directly by devShells (outside the module system).
  phpLib = config: import ./php-lib.nix { inherit pkgs config; };
}
