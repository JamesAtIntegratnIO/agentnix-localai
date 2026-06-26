{
  description = "jdreier macOS system managed with nix-darwin + Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    openspec.url = "github:Fission-AI/OpenSpec";
    hermes-agent.url = "github:NousResearch/hermes-agent/v2026.6.19";

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
          # a2a-sdk tests fail on darwin due to FastAPI introspection issues
          # (AttributeError: Can't get local object 'FastAPI.setup.<locals>.openapi').
          # Since pytest runs during buildPhase via the pyproject build system,
          # disabledTests and nativeCheckInputs overrides don't help.
          # Remove the failing test file before build starts.
          a2a-sdk = super.a2a-sdk.overrideAttrs (old: {
            postPatch = ''
              rm -f tests/e2e/push_notifications/test_default_push_notification_support.py
            '' + (old.postPatch or "");
          });

          lmstudio = super.lmstudio.overrideAttrs (old: {
            version = "0.4.17-4";
            src = super.fetchurl {
              url = "https://installers.lmstudio.ai/darwin/arm64/${old.version}/LM-Studio-${old.version}-arm64.dmg";
              sha256 = "sha256-r8LykADF4Lw6jVucPIwyUXOUyBxOjvgQUU0XpGhY02E=";
            };
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
