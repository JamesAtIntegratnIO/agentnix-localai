# Builds the opencode.json config attrset from caller-supplied inputs.
# Returns a plain Nix attrset — not a derivation.
# Consumers pass this to builtins.toJSON or pkgs.writeText.
#
# Arguments:
#   models      — attrset with { model, small_model, provider } (from your models.nix)
#   mcpServers  — attrset merged into the opencode.json `mcp` block
#   extraConfig — attrset merged last; can override any key including compaction
{ models, mcpServers ? {}, extraConfig ? {} }:
  {
    "$schema"   = "https://opencode.ai/config.json";
    autoupdate  = false;
    model       = models.model;
    small_model = if builtins.hasAttr "small_model" models then models.small_model else null;
    provider    = models.provider;

    # Sane defaults for local model usage: auto-compact when context is full and
    # prune old tool outputs so large thinking models don't overflow the window.
    compaction = {
      auto  = true;
      prune = true;
    };
  }
  // (if mcpServers != {} then { mcp = mcpServers; } else {})
  // extraConfig
