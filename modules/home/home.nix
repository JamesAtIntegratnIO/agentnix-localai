{ pkgs, username, lib, inputs, ... }:
let
  homePackages = import ./packages.nix { inherit pkgs; };
  opencodeModule = import ./opencode/default.nix { inherit pkgs username lib inputs; };
in
lib.mkMerge [
  {
    home.username = username;
    home.homeDirectory = "/Users/${username}";

    # Keep this at the Home Manager version you started with.
    home.stateVersion = "24.11";

    programs.home-manager.enable = true;

    home.packages = homePackages;

    programs.git = {
      enable = true;
      settings = {
        user.name = "James Dreier";
        user.email = "james@integratn.io";
      };
    };

    programs.zsh = {
      enable = true;
      shellAliases = {
        ll = "eza -la";
        ls = "eza";
        grep = "rg";
      };
      # cq shell completion
      initContent = ''
        source <(cq completion zsh)
      '';
    };

    # cq — store knowledge DB in a stable path shared with the MCP server config.
    home.sessionVariables = {
      CQ_LOCAL_DB_PATH = "/Users/${username}/.local/share/cq/knowledge.db";
      OPENCODE_ENABLE_EXA = "1";
    };
  }

  opencodeModule
]
