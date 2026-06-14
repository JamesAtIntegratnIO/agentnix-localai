{ pkgs }:
let
  cq = pkgs.callPackage ./pkgs/cq.nix {};

  # Version control & security
  vcs = with pkgs; [
    git
    gnupg
  ];

  # Editors
  editors = with pkgs; [
    neovim
  ];

  # Network & download utilities
  network = with pkgs; [
    wget
    curl
  ];

  # System monitoring
  monitoring = with pkgs; [
    htop
  ];

  # Data & scripting utilities
  utils = with pkgs; [
    jq
  ];

  # Languages & runtimes
  languages = with pkgs; [
    go
    golangci-lint
    uv   # Python package runner — needed for uvx mcp-server-qdrant
  ];

  # Local AI stack — cq is a custom derivation defined above.
  ai = [ pkgs.ollama pkgs.qdrant cq ];
in {
  # Named derivations consumed by other modules.
  inherit cq;
  # Flat list for environment.systemPackages.
  all = vcs ++ editors ++ network ++ monitoring ++ utils ++ languages ++ ai;
}
