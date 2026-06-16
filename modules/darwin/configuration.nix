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
  # We use a symlink instead of cp -rL so the directory creation is safe (other apps
  # placed here won't be destroyed on rebuild) and the operation is atomic.
  # Note: rm -rf is needed here because LM Studio.app is a directory; we target only
  # the specific file to avoid destroying other apps in the directory.
  system.activationScripts.applications.text = pkgs.lib.mkForce ''
    echo "setting up /Applications/Nix Apps..." >&2
    mkdir -p /Applications/Nix\ Apps
    rm -rf "/Applications/Nix Apps/LM Studio.app"
    ln -sfT ${pkgs.lmstudio}/Applications/LM\ Studio.app "/Applications/Nix Apps/LM Studio.app"
  '';

  environment.systemPackages = packages.all;

  nix.enable = false;

  system.primaryUser = username;

  # Used for backwards-compatible defaults; bump only after reading release notes.
  system.stateVersion = 5;
}
