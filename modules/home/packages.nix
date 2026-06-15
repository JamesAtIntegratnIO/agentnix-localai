{ pkgs }:
let
  # Better grep / find replacements
  search = with pkgs; [
    ripgrep
    fd
  ];

  # Better coreutils replacements
  coreutils = with pkgs; [
    tree
    bat   # cat with syntax highlighting
    eza   # ls replacement
  ];

  # AI / LLM tools
  ai = with pkgs; [
    lmstudio
  ];

  # Project scaffolding
  scaffolding = with pkgs; [
    cookiecutter
  ];
in
  search ++ coreutils ++ ai ++ scaffolding
