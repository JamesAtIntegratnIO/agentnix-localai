{ pkgs, username, cq }:
{
  "$schema" = "https://opencode.ai/config.json";
  autoupdate = false;
  model = "lmstudio/qwen/qwen3-coder-next";
  small_model = "ollama/qwen2.5-coder:14b";

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

  provider = {
    # LM Studio local server — load Qwen3-Coder-Next-MLX-4bit in the LM Studio UI first.
    # LM Studio ignores the model ID in requests and uses whatever is currently loaded.
    "lmstudio" = {
      npm = "@ai-sdk/openai-compatible";
      name = "LM Studio (local)";
      options = {
        baseURL = "http://127.0.0.1:1234/v1";
        apiKey = "lmstudio";
      };
      models = {
        "qwen/qwen3-coder-next" = { name = "Qwen3 Coder Next 80B MLX 4bit"; };
      };
    };

    "ollama" = {
      npm = "@ai-sdk/openai-compatible";
      name = "Ollama (local)";
      options = {
        baseURL = "http://127.0.0.1:11434/v1";
        apiKey = "ollama";
      };
      models = {
        "qwen2.5-coder:14b" = { name = "Qwen2.5 Coder 14B (fast)"; };
        "nomic-embed-text"  = { name = "Nomic Embed Text"; };
      };
    };
  };
}
