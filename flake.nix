{
  description = "jdreier macOS system managed with nix-darwin + Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    openspec.url = "github:Fission-AI/OpenSpec";

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
      pkgsConfig = {
        allowUnfree = true;
        overrides = self: super: {
          # a2a-sdk has darwin-specific test failures (FastAPI introspection).
          # disabledTests in nixpkgs only affects checkPhase, but tests run during
          # buildPhase via pytest hooks in the pyproject build system.
          # Strip test deps from nativeCheckInputs to prevent test execution.
          a2a-sdk = super.a2a-sdk.overrideAttrs (old: {
            nativeCheckInputs = with old; lib.filter (p:
              p.pname or "" != "pytest-asyncio" &&
              p.pname or "" != "pytest-cov-stub" &&
              p.pname or "" != "pytest-timeout" &&
              p.pname or "" != "pytest-xdist" &&
              p.pname or "" != "pytestCheckHook" &&
              p.pname or "" != "respx"
            ) nativeCheckInputs;
          });
        };
      };
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
              inherit inputs username;
            };
            home-manager.users.${username} = import ./modules/home/home.nix;
          }
        ];
      };
    };
}
