{ pkgs, ... }:

let
  # LiteLLM proxy with only the deps needed for `litellm --config` to start.
  # We list these explicitly instead of using the full `proxy` optional-dependencies
  # group because the proxy group pulls in `a2a-sdk`, which has tests that run during
  # the build phase (not check phase), making `doCheck = false` ineffective.
  proxyDeps = with pkgs.python3Packages; [
    uvicorn      # ASGI server
    fastapi      # web framework
    pyyaml       # config parsing
    python-dotenv # env var loading
    httpx        # HTTP client
    anyio        # async I/O
    click        # CLI framework
    rich         # pretty output
    uvloop       # async event loop (optional, drops CPU usage)
    orjson       # fast JSON parser
    websockets   # WebSocket support for streaming
    python-multipart # form data parsing
  ];

  litellmProxy = pkgs.litellm.overrideAttrs (old: {
    propagatedBuildInputs = (old.propagatedBuildInputs or []) ++ proxyDeps;
  });

  configYaml = pkgs.writeText "litellm-config.yaml" ''
    model_list:
      - model_name: lmstudio/qwen3.6-35b
        litellm_params:
          model: openai/lmstudio-ai/qwen3.6-35b-a3b
          api_base: http://127.0.0.1:1234/v1
          api_key: ""
      - model_name: lmstudio/qwen3-coder
        litellm_params:
          model: openai/lmstudio-ai/qwen3-coder-next
          api_base: http://127.0.0.1:1234/v1
          api_key: ""

    litellm_settings:
      drop_params: true
  '';
in
{
  inherit litellmProxy configYaml;
}
