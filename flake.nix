{
  description = "Tung's nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's a working example:
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Nixvim
    nixvim.url = "github:nix-community/nixvim/nixos-25.11";

    # Additional PHP versions
    phps.url = "github:fossar/nix-phps";
    phps.inputs.nixpkgs.follows = "nixpkgs";

    nix-jetbrains-plugins.url = "github:nix-community/nix-jetbrains-plugins";

    agenix.url = "github:ryantm/agenix";
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , agenix
    , ...
    }@inputs:
    let
      # Supported systems for your flake packages, shell, etc.
      systems = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      # This is a function that generates an attribute by calling a function you
      # pass to it, with each system as an argument
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      # Your custom packages
      # Accessible through 'nix build', 'nix shell', etc
      # phpLib is excluded — it requires the phps overlay and is not a standalone package.
      packages = forAllSystems (
        system: removeAttrs (import ./pkgs nixpkgs.legacyPackages.${system}) [ "phpLib" ]
      );

      # Formatter for your nix files, available through 'nix fmt'
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);

      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };

      # Reusable nixos modules you might want to export
      # These are usually stuff you would upstream into nixpkgs
      nixosModules = import ./modules/nixos;

      # Reusable home-manager modules you might want to export
      # These are usually stuff you would upstream into home-manager
      homeManagerModules = import ./modules/home-manager;

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#nixos-vmware'
      nixosConfigurations = {
        nixos-vmware = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./nixos/configuration.nix
          ];
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
      #      they are already available via the overlays. Wrap with pkgs.lib.hiPrio to
      #      ensure the right `php` binary wins on PATH.
      #   2. In the project root, create/update .envrc:
      #        use flake /home/tung/code/nix-configs#my-project
      #   3. Run: direnv allow
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [
              self.overlays.additions
              self.overlays.modifications
              self.overlays.unstable-packages
              self.overlays.phps
            ];
          };

          phpDefaults = import ./pkgs/php-config.nix;
          php = pkgs.phpLib phpDefaults;
        in
        {
          # netsuite-middleware — PHP 8.1 (EOL, via phps overlay); migrate to 8.2 when ready
          middleware = pkgs.mkShell {
            buildInputs = [
              (pkgs.lib.hiPrio pkgs.php81)
              pkgs.php81.packages.composer
            ];
            PHP_INI_SCAN_DIR = php.versions.php81.cliIniScanDir;
          };
          # prbot — PHP 8.1 (EOL, via phps overlay)
          prbot = pkgs.mkShell {
            buildInputs = [
              (pkgs.lib.hiPrio pkgs.php81)
              pkgs.php81.packages.composer
            ];
            PHP_INI_SCAN_DIR = php.versions.php81.cliIniScanDir;
          };
          # admin_ci3 (v3) — PHP 8.3
          v3 = pkgs.mkShell {
            buildInputs = [
              (pkgs.lib.hiPrio pkgs.php83)
              pkgs.php83.packages.composer
            ];
            PHP_INI_SCAN_DIR = php.versions.php83.cliIniScanDir;
          };
          # fc-es-starter-pack — Java 8, Maven 3.6.3 (nixpkgs only ships latest Maven;
          # override version/hash to pin 3.6.3)
          fc-es-starter-pack = pkgs.mkShell {
            buildInputs = [
              pkgs.jdk8
              pkgs.maven363
              pkgs.nodejs
              pkgs.jq
            ];
            JAVA_HOME = "${pkgs.jdk8}";
          };
        }
      );

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#tung@nixos-vmware'
      homeConfigurations = {
        "tung@nixos-vmware" = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
            overlays = [
              self.overlays.additions
              self.overlays.modifications
              self.overlays.unstable-packages
              self.overlays.phps
            ];
          };
          extraSpecialArgs = {
            inherit inputs;
          };
          modules = [
            ./home-manager/home.nix
            agenix.homeManagerModules.default
          ];
        };
      };
    };
}
