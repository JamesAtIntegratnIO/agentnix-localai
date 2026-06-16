## Why

Opencode has LSP integration for diagnostics (error checking, linting feedback for the agent) but it is disabled by default and no LSP server binaries are installed. The agent cannot receive language-server diagnostics for Go, Python, JavaScript, or Nix files — the languages most relevant to this project.

## What Changes

- **Install LSP server binaries** for four languages:
  - **gopls** (Go) — auto-installed by opencode when `go` command is available (already installed)
  - **pyright** (Python) — new npm package
  - **typescript-language-server** (JS/TS) — new npm package
  - **nixd** (Nix) — new Nix package
- **Enable LSP in opencode config** — add `"lsp": true` so opencode auto-discovers and launches servers when relevant file extensions are opened
- **Grant LSP permission to all agents** — add `lsp = "allow"` to the common permission set so any agent can invoke the `diagnostics` tool

## Capabilities

### New Capabilities
- `lsp-servers`: Declarative installation of LSP server binaries (pyright, typescript-language-server, nixd) into the Nix home configuration

### Modified Capabilities
- `opencode-config`: Adds `lsp` configuration key and enables LSP in the generated opencode.json
- `agent-permissions`: Adds `lsp` permission to the common agent permission set

## Impact

- `modules/darwin/packages.nix` — add nixd
- `modules/home/packages.nix` — add pyright, typescript-language-server (via npm)
- `modules/opencode/lib/config.nix` — wire in LSP config key
- `modules/home/opencode/default.nix` — pass LSP setting into mkOpencodeEnv
- `modules/home/opencode/agent-defs/common.nix` — add `lsp = "allow"` to commonPermission and mkSubagentPermission
