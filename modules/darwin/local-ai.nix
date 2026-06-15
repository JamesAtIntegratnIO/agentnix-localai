{ config, pkgs, lib, username, ... }:
let
  logDir = "/Users/${username}/Library/Logs/local-ai";
  qdrantDataDir = "/Users/${username}/Library/Application Support/local-ai/qdrant";
in
{
  # Keep the local AI directories writable for launchd user agents.
  # Qdrant writes temporary snapshot data relative to CWD.
  system.activationScripts.localAiDirs.text = ''
    /bin/mkdir -p "${logDir}" "${qdrantDataDir}"
    /usr/sbin/chown -R ${username}:staff "/Users/${username}/Library/Logs/local-ai" "/Users/${username}/Library/Application Support/local-ai"
  '';

  # Qdrant vector-database config.
  environment.etc."local-ai/qdrant.yaml".text = ''
    storage:
      storage_path: ${qdrantDataDir}

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
      WorkingDirectory = qdrantDataDir;
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
