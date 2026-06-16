## Goal

Enable LSP diagnostics for Go, Python, JavaScript/TypeScript, and Nix files in opencode, with all agents able to invoke diagnostics.

## Decisions

### D1: Use opencode's built-in LSP auto-installation where possible

Opencode auto-installs several LSP servers (gopls, bash, typescript, etc.) when the relevant package is available in the workspace. For gopls, opencode will auto-install when `go` is on PATH (already installed). For typescript, opencode auto-installs typescript-language-server when `typescript` is in the project.

**Decision**: Let opencode handle auto-installation for gopls and typescript. Only add nixd and pyright as explicit Nix packages since they need to be on PATH for opencode's built-in detection.

### D2: Set lsp to true (enable all built-ins)

The opencode config supports `"lsp": true` (enable all built-in servers) or `"lsp": {}` (enable with ability to override). Since we want diagnostics for go, nix, python, and js/tsx files — all of which have built-in servers — `"lsp": true` is the simplest approach.

**Decision**: Use `"lsp": true` in the opencode config.

### D3: Add nixd and pyright to user packages, not system packages

nixd and pyright are developer tools used per-user, not system-wide. The existing pattern in this repo puts developer tools in `modules/home/packages.nix` (user packages) while system-level tools go in `modules/darwin/packages.nix`.

**Decision**: Add nixd to `modules/darwin/packages.nix` (it's a Nix tool, already fits the pattern of nix-related tools being system-level), and pyright + typescript-language-server to `modules/home/packages.nix`.

Actually, looking at the existing patterns more carefully:
- `modules/darwin/packages.nix` has `languages = [ go golangci-lint uv ]` — these are language toolchains
- `modules/home/packages.nix` has `search`, `coreutils`, `ai`, `scaffolding` groups

**Decision**: Add nixd to `modules/darwin/packages.nix` in the `languages` group. Add pyright and typescript-language-server to `modules/home/packages.nix` in a new `lsp` group.

### D4: Wire LSP through extraConfig in mkOpencodeEnv

The `mkOpencodeEnv` function already accepts `extraConfig` which is merged last into the config. This is the least invasive path — no changes to the config builder signature needed.

**Decision**: Add `extraConfig = { lsp = true; }` in `modules/home/opencode/default.nix` when calling `mkOpencodeEnv`.

### D5: Add lsp = "allow" to both commonPermission and mkSubagentPermission

All agents inherit from commonPermission. Subagents use mkSubagentPermission. Both need the lsp permission to invoke diagnostics.

**Decision**: Add `lsp = "allow"` to both permission sets in common.nix.

## Architecture

```
┌─────────────────────────────────────────────┐
│            Nix Build Time                    │
│                                              │
│  modules/darwin/packages.nix                 │
│    └── nixd                                   │
│                                              │
│  modules/home/packages.nix                   │
│    └── pyright, typescript-language-server   │
│                                              │
│  modules/home/opencode/default.nix           │
│    └── extraConfig = { lsp = true }          │
│         → mkOpencodeEnv → opencode.json      │
│                                              │
│  modules/home/opencode/agent-defs/common.nix │
│    └── lsp = "allow"                         │
│         → agent .md files                    │
└─────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────┐
│            Runtime (opencode)                │
│                                              │
│  User opens a .go file → opencode starts     │
│  gopls (auto-installed). Agent calls         │
│  diagnostics tool → gets errors.             │
│                                              │
│  User opens a .py file → opencode starts     │
│  pyright (on PATH). Agent calls diagnostics. │
│                                              │
│  User opens a .nix file → opencode starts    │
│  nixd (on PATH). Agent calls diagnostics.    │
│                                              │
│  User opens a .ts/.js file → opencode starts │
│  typescript-language-server (auto-installed).│
└─────────────────────────────────────────────┘
```

## Files Changed

| File | Change |
|---|---|
| `modules/darwin/packages.nix` | Add `nixd` to languages group |
| `modules/home/packages.nix` | Add `lsp` group with `pyright` and `typescript-language-server` |
| `modules/home/opencode/default.nix` | Add `extraConfig = { lsp = true; }` to mkOpencodeEnv call |
| `modules/home/opencode/agent-defs/common.nix` | Add `lsp = "allow"` to commonPermission and mkSubagentPermission |
