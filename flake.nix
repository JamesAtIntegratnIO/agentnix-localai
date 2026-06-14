{
  description = "jdreier macOS system managed with nix-darwin + Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:lnl7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, ... }:
    let
      hostname = "mac-studio";
      username = "jdreier";
      system = "aarch64-darwin";
      pkgsConfig = { allowUnfree = true; };
    in
    {
      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = {
          inherit inputs hostname username;
        };
        modules = [
          ./modules/darwin/configuration.nix
          { nixpkgs.config = pkgsConfig; }
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit username;
            };
            home-manager.users.${username} = import ./modules/home/home.nix;
          }
        ];
      };
    };
}
