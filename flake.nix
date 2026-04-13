{
  description = "Tung's nix config";

  inputs = {
    # Nixpkgs
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    # home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Nixvim
    # nixvim.url = "github:nix-community/nixvim/nixos-25.11";
    nixvim.url = "github:nix-community/nixvim/main";

    # Additional PHP versions
    phps.url = "github:fossar/nix-phps";
    phps.inputs.nixpkgs.follows = "nixpkgs";

    nix-jetbrains-plugins.url = "github:nix-community/nix-jetbrains-plugins";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-jetbrains-plugins,
      phps,
      ...
    }@inputs:
    let
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ phps.overlays.default ];
        };
    in
    {
      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#nixos-vmware'
      nixosConfigurations = {
        nixos-vmware = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          # > Our main nixos configuration file <
          modules = [ ./nixos/configuration.nix ];
        };
      };

      # Dev shells for local projects.
      #
      # To add a new project:
      #   1. Add a shell here, e.g.:
      #        my-project = pkgs.mkShell {
      #          buildInputs = [ pkgs.php83 pkgs.php83.packages.composer ];
      #        };
      #      For EOL PHP versions (< 8.2) use pkgs.phpXY from the phps overlay —
      #      they are already available via pkgsFor. Wrap with pkgs.lib.hiPrio to
      #      ensure the right `php` binary wins on PATH.
      #   2. In the project root, create/update .envrc:
      #        use flake /home/tung/code/nix-configs#my-project
      #   3. Run: direnv allow
      devShells.x86_64-linux =
        let
          pkgs = pkgsFor "x86_64-linux";
        in
        {
          # netsuite-middleware — PHP 8.1 (EOL, via phps overlay); migrate to 8.2 when ready
          middleware = pkgs.mkShell {
            buildInputs = [
              (pkgs.lib.hiPrio pkgs.php81)
              pkgs.php81.packages.composer
            ];
          };
          # prbot — PHP 8.1 (EOL, via phps overlay)
          prbot = pkgs.mkShell {
            buildInputs = [
              (pkgs.lib.hiPrio pkgs.php81)
              pkgs.php81.packages.composer
            ];
          };
          # admin_ci3 (v3) — PHP 8.3
          v3 = pkgs.mkShell {
            buildInputs = [
              (pkgs.lib.hiPrio pkgs.php83)
              pkgs.php83.packages.composer
            ];
          };
          # fc-es-starter-pack — Java 8, Maven 3.6.3 (nixpkgs only ships latest Maven;
          # override version/hash to pin 3.6.3)
          fc-es-starter-pack =
            let
              maven363 = pkgs.maven.overrideAttrs {
                version = "3.6.3";
                src = pkgs.fetchurl {
                  url = "https://repo1.maven.org/maven2/org/apache/maven/apache-maven/3.6.3/apache-maven-3.6.3-bin.tar.gz";
                  hash = "sha256-Jq2R11GzqaUwh676dD9OFqF3QdORWyGc90ESv4ekOMU=";
                };
              };
            in
            pkgs.mkShell {
              buildInputs = [
                pkgs.jdk8
                maven363
                pkgs.nodejs
                pkgs.jq
              ];
              JAVA_HOME = "${pkgs.jdk8}";
            };
        };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#tung@nixos-vmware'
      homeConfigurations = {
        "tung@nixos-vmware" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor "x86_64-linux";
          extraSpecialArgs = { inherit inputs; };
          # > Our main home-manager configuration file <
          modules = [ ./home-manager/home.nix ];
        };
      };
    };
}
