## Tasks

- [x] 1. Add `nixd` to the `languages` group in `modules/darwin/packages.nix`
- [x] 2. Add `lsp` group with `pyright` and `typescript-language-server` to `modules/home/packages.nix`
- [x] 3. Add `extraConfig = { lsp = true; }` to the `mkOpencodeEnv` call in `modules/home/opencode/default.nix`
- [x] 4. Add `lsp = "allow"` to `commonPermission` in `modules/home/opencode/agent-defs/common.nix`
- [x] 5. Add `lsp = "allow"` to the permission set returned by `mkSubagentPermission` in `modules/home/opencode/agent-defs/common.nix`
- [x] 6. Verify `nix build` succeeds and opencode.json contains `"lsp": true`
- [x] 7. Verify opencode can detect and use LSP servers for .go, .py, .ts, and .nix files
