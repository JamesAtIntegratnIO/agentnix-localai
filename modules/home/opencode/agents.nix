{ pkgs, lib }:
let
  common = import ./agent-defs/common.nix {};
  agentDefs = import ./agent-defs {};
  permissionOrder = common.permissionOrder;

  renderPermissionEntry = permission: key:
    let
      value = permission.${key};
    in
    if builtins.isAttrs value then
      let
        bashKeys = builtins.attrNames value;
        bashLines = map (bashKey: "    ${builtins.toJSON bashKey}: ${value.${bashKey}}") bashKeys;
      in
      "  ${key}:\n${lib.concatStringsSep "\n" bashLines}"
    else
      "  ${key}: ${value}";

  renderFrontMatter = def:
    let
      keys = builtins.filter (k: builtins.hasAttr k def.permission) permissionOrder;
      permissionLines = map (k: renderPermissionEntry def.permission k) keys;
      stepsLine = lib.optionalString (builtins.hasAttr "steps" def) "steps: ${toString def.steps}\n";
    in
    ''
      ---
      description: ${def.description}
      mode: ${def.mode}
      ${stepsLine}temperature: ${toString def.temperature}
      permission:
      ${lib.concatStringsSep "\n" permissionLines}
      ---

    '';

  renderAgent = name: def:
    let
      frontMatter = renderFrontMatter def;
    in
    pkgs.runCommand "opencode-agent-${name}.md" {} ''
      cat > "$out" <<'EOF'
      ${frontMatter}
      EOF
      cat >> "$out" <<'EOF'
      ${def.body}
      EOF
    '';
in
{
  # Agent markdown is generated from shared Nix defaults + role overrides.
  home.file = lib.mapAttrs' (name: def:
    lib.nameValuePair ".config/opencode/agents/${name}.md" {
      source = renderAgent name def;
    }
  ) agentDefs;
}
