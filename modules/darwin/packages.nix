{ pkgs }:
let
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

  # Local AI stack
  ai = [ pkgs.ollama pkgs.qdrant ];
in {
  # Flat list for environment.systemPackages.
  all = vcs ++ editors ++ network ++ monitoring ++ utils ++ languages ++ ai;
}
