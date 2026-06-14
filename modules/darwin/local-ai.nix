{ config, pkgs, lib, username, ... }:
let
  logDir = "/Users/${username}/Library/Logs/local-ai";
in
{
  # No activation script needed — ~/Library/Logs is user-owned and always exists.
  # launchd user agents can create subdirs themselves via WorkingDirectory,
  # but the simplest fix is simply pointing logs at a path that always exists.

  # Qdrant vector-database config.
  environment.etc."local-ai/qdrant.yaml".text = ''
    storage:
      storage_path: /Users/${username}/Library/Application Support/local-ai/qdrant

    service:
      host: 127.0.0.1
      http_port: 6333
      grpc_port: 6334
  '';

  # Ollama — user agent for Metal/GPU access.
  launchd.user.agents.ollama = {
    serviceConfig = {
      Label = "org.nixos.ollama";
      ProgramArguments = [ "${pkgs.ollama}/bin/ollama" "serve" ];
      EnvironmentVariables = {
        OLLAMA_HOST = "127.0.0.1:11434";
        OLLAMA_MODELS = "/Users/${username}/Library/Application Support/local-ai/ollama";
      };
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${logDir}/ollama.log";
      StandardErrorPath = "${logDir}/ollama.err";
    };
  };

  # Qdrant vector database.
  launchd.user.agents.qdrant = {
    serviceConfig = {
      Label = "org.nixos.qdrant";
      ProgramArguments = [
        "${pkgs.qdrant}/bin/qdrant"
        "--config-path" "/etc/local-ai/qdrant.yaml"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${logDir}/qdrant.log";
      StandardErrorPath = "${logDir}/qdrant.err";
    };
  };

}
