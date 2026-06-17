{ pkgs, ... }:

let
  litellmProxy = pkgs.litellm.overrideAttrs (old: {
    propagatedBuildInputs = (old.propagatedBuildInputs or [])
      ++ (with pkgs.litellm.optional-dependencies; proxy);
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
