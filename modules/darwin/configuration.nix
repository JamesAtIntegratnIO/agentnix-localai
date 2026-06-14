{ pkgs, hostname, username, ... }:
let
  packages = import ./packages.nix { inherit pkgs; };
in
{
  imports = [ ./local-ai.nix ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Match this host's architecture (Apple Silicon Mac Studio).
  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = hostname;

  users.users.${username} = {
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  # Copy GUI apps from the nix store into /Applications/Nix Apps so Spotlight finds them.
  # We interpolate store paths directly so this runs correctly at activation time,
  # before Home Manager has a chance to populate ~/Applications.
  system.activationScripts.applications.text = pkgs.lib.mkForce ''
    echo "setting up /Applications/Nix Apps..." >&2
    rm -rf /Applications/Nix\ Apps
    mkdir -p /Applications/Nix\ Apps
    cp -rL ${pkgs.lmstudio}/Applications/LM\ Studio.app /Applications/Nix\ Apps/
  '';

  environment.systemPackages = packages.all;

  nix.enable = false;

  system.primaryUser = username;

  # Used for backwards-compatible defaults; bump only after reading release notes.
  system.stateVersion = 5;
}
