{ pkgs, username, inputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  hermesPackages = inputs.hermes-agent.packages.${system};

  # Choose the base package; switch to hermesPackages.messaging or
  # hermesPackages.full if you need those dependency groups sealed at build time.
  hermesPackage = hermesPackages.default;

  # Non-secret baseline config. Keep provider credentials in ~/.hermes/.env.
  hermesConfig = (pkgs.formats.yaml {}).generate "hermes-config.yaml" {
    model.default = "anthropic/claude-sonnet-4";
    terminal = {
      backend = "local";
      timeout = 180;
    };
    toolsets = [ "all" ];
  };
in
{
  home.packages = [ hermesPackage ];

  home.sessionVariables = {
    HERMES_HOME = "/Users/${username}/.hermes";
  };

  home.file.".hermes/config.yaml".source = hermesConfig;

  home.file.".hermes/.env.example".text = ''
    # Copy to ~/.hermes/.env and add your real keys. Do not commit secrets.
    OPENROUTER_API_KEY=replace-me
    # ANTHROPIC_API_KEY=replace-me
  '';
}
