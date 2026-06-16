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

  permissionOrder = [
    "read"
    "edit"
    "glob"
    "grep"
    "list"
    "bash"
    "task"
    "skill"
    "question"
    "webfetch"
    "websearch"
    "external_directory"
    "doom_loop"
    "lsp"
  ];
}