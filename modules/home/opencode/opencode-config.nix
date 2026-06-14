{ pkgs, username, cq }:
let
  modelConfig = import ./models.nix;
in
{
  "$schema" = "https://opencode.ai/config.json";
  autoupdate = false;

  # Keep context manageable for local models: auto-compact when full and
  # prune old tool outputs so qwen3's thinking tokens don't overflow the window.
  compaction = {
    auto = true;
    prune = true;
  };

  mcp = {
    cq = {
      type = "local";
      enabled = true;
      command = [ "${cq}/bin/cq" "mcp" ];
      environment = {
        CQ_LOCAL_DB_PATH = "/Users/${username}/.local/share/cq/knowledge.db";
      };
    };
    # mcp-server-qdrant: semantic memory — store/retrieve information via Qdrant.
    # Agents use qdrant-store to save knowledge and qdrant-find to recall it.
    qdrant = {
      type = "local";
      enabled = true;
      command = [ "${pkgs.uv}/bin/uvx" "mcp-server-qdrant" ];
      environment = {
        QDRANT_URL = "http://127.0.0.1:6333";
        COLLECTION_NAME = "opencode-memory";
        # fastembed is the only supported embedding provider.
        # Model downloads ~90MB on first use to ~/.cache/fastembed/
        EMBEDDING_MODEL = "sentence-transformers/all-MiniLM-L6-v2";
      };
    };
  };

} // modelConfig
