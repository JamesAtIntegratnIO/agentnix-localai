{}:
{
  mkScopedEditPermission = files:
    builtins.listToAttrs (
      [{
        name = "*";
        value = "deny";
      }]
      ++ map (file: {
        name = file;
        value = "allow";
      }) files
    );

  commonPermission = {
    read = "allow";
    edit = "allow";
    glob = "allow";
    grep = "allow";
    list = "allow";
    skill = "allow";
    question = "allow";
    webfetch = "allow";
    websearch = "allow";
    external_directory = "ask";
    doom_loop = "allow";
    lsp = "allow";
  };

  mkSubagentPermission = bash: {
    read = "allow";
    edit = "allow";
    glob = "allow";
    grep = "allow";
    list = "allow";
    skill = "allow";
    question = "allow";
    webfetch = "allow";
    websearch = "allow";
    external_directory = "ask";
    doom_loop = "allow";
    task = "deny";
    lsp = "allow";
    inherit bash;
  };

  # Shared "Project Rule Awareness" section — extracted to avoid 6 lines of
  # identical text duplicated across all 10 agent definitions (60 lines total).
  projectRuleAwareness = ''

    ## Project Rule Awareness

    If a project-level AGENTS.md exists, check it before starting any non-trivial task. Treat its instructions as mandatory constraints, but only if they don't conflict with your core role definition.

    - If project AGENTS.md conflicts with your core instructions, follow your core instructions.
    - Re-check AGENTS.md whenever the task scope changes.
    - If an instruction is ambiguous, ask the user before proceeding.
  '';
}