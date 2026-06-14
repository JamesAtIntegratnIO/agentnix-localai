let
  providers = {
    # LM Studio local server — load Qwen3-Coder-Next-MLX-4bit in the LM Studio UI first.
    # LM Studio ignores the model ID in requests and uses whatever is currently loaded.
    lmstudio = {
      npm = "@ai-sdk/openai-compatible";
      name = "LM Studio (local)";
      options = {
        baseURL = "http://127.0.0.1:1234/v1";
        apiKey = "lmstudio";
      };
    };

    ollama = {
      npm = "@ai-sdk/openai-compatible";
      name = "Ollama (local)";
      options = {
        baseURL = "http://127.0.0.1:11434/v1";
        apiKey = "ollama";
      };
    };
  };

  # Single source of truth: define each model once.
  # role = "primary" sets model; role = "small" sets small_model.
  # role = "available" (or omitting role) keeps a model selectable without
  # assigning it as a default.
  models = [
    {
        provider = "lmstudio";
        id = "qwen/qwen3.6-35b-a3b";
        title = "Qwen3.6 35B A3B (fast)";
        role = "primary";
    }
    {
      provider = "lmstudio";
      id = "qwen/qwen3-coder-next";
      title = "Qwen3 Coder Next 80B MLX 4bit";
      role = "available";
    }
    {
      provider = "ollama";
      id = "qwen2.5-coder:14b";
      title = "Qwen2.5 Coder 14B (fast)";
      role = "small";
    }
    {
      provider = "ollama";
      id = "nomic-embed-text";
      title = "Nomic Embed Text";
      role = "available";
    }
  ];

  validRoles = [ "primary" "small" "available" null ];

  invalidRoleModels = builtins.filter
    (m: !(builtins.elem (m.role or null) validRoles))
    models;

  roleValidation =
    if invalidRoleModels == [ ] then
      true
    else
      let
        badModel = builtins.head invalidRoleModels;
        badRole = badModel.role or null;
      in
      throw "Invalid role '${toString badRole}' for model '${badModel.provider}/${badModel.id}' in modules/home/opencode/models.nix. Allowed roles: primary, small, available, or omit role.";

  modelRef = m: "${m.provider}/${m.id}";

  findByRole = role:
    let
      matches = builtins.filter (m: (m.role or null) == role) models;
    in
    if builtins.length matches == 1 then
      builtins.head matches
    else
      throw "Expected exactly one model with role '${role}' in modules/home/opencode/models.nix";

  modelsForProvider = providerName:
    builtins.listToAttrs (
      map (m: {
        name = m.id;
        value = { name = m.title; };
      })
      (builtins.filter (m: m.provider == providerName) models)
    );

  provider = builtins.mapAttrs
    (providerName: providerConfig:
      providerConfig // {
        models = modelsForProvider providerName;
      })
    providers;

  primaryModel = findByRole "primary";
  smallModel = findByRole "small";
in
assert roleValidation;
{
  model = modelRef primaryModel;
  small_model = modelRef smallModel;
  inherit provider;
}
