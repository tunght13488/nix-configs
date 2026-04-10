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
      ...
    }@inputs:
    let
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

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#tung@nixos-vmware'
      homeConfigurations = {
        "tung@nixos-vmware" = home-manager.lib.homeManagerConfiguration {
          # Home-manager requires 'pkgs' instance
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs; };
          # > Our main home-manager configuration file <
          modules = [ ./home-manager/home.nix ];
        };
      };
    };
}
