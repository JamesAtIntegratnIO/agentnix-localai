# Reference

Complete reference for all configuration, services, and tools managed by this flake.

---

## Table of Contents

- [System Configuration](#system-configuration)
- [Local AI Services](#local-ai-services)
- [Opencode Environment](#opencode-environment)
- [Agents](#agents)
- [Environment Variables](#environment-variables)
- [Ownership Guide](#ownership-guide)
- [Troubleshooting](#troubleshooting)

---

## System Configuration

### Project Structure

```
flake.nix                        Entry point. Wires nixpkgs, nix-darwin, home-manager, openspec.

modules/
  darwin/
    configuration.nix            Host settings, system packages, app activation scripts.
    packages.nix                 System package groups (vcs, editors, network, ai stack).
    local-ai.nix                 launchd user agents: qdrant (on), ollama (off by default), litellm (off by default).
    litellm-proxy/default.nix    LiteLLM proxy packaging + config YAML generation.

  home/
    home.nix                     Home Manager root: git, zsh, env vars, opencode module.
    packages.nix                 User-level packages (ripgrep, bat, eza, LSP servers, etc.).
    opencode/
      default.nix                Owns opencode + cq + openspec + qdrant MCP wiring.
      models.nix                 Model/provider declarations with role assignments.
      agent-defs/                One .nix file per agent (10 agents total).
        common.nix               Shared fields and projectRuleAwareness template.
        default.nix              Validates agents, assembles the full agent attrset.
        architect.nix            …and one file per agent role.
      pkgs/
        cq.nix                   Nix derivation that builds the cq binary from source.

  opencode/
    default.nix                  mkOpencodeEnv — pure builder, no Home Manager dependency.
    lib/
      config.nix                 Builds the opencode.json attrset from inputs.
      agents.nix                 Renders agent .md files with frontmatter + body.
```

### System Packages

Defined in `modules/darwin/packages.nix`, installed into `environment.systemPackages`:

| Group | Contents |
|---|---|
| `vcs` | git, gnupg |
| `editors` | neovim |
| `network` | wget, curl |
| `monitoring` | htop |
| `utils` | jq |
| `languages` | go, golangci-lint, nixd (LSP), uv (Python runner) |
| `ai` | lmstudio, ollama, qdrant, litellm |

### User Packages

Defined in `modules/home/packages.nix`, installed into `home.packages`:

| Group | Contents |
|---|---|
| `search` | ripgrep, fd |
| `coreutils` | tree, bat, eza |
| `ai` | lmstudio (also in system; kept here for home profile visibility) |
| `lsp` | pyright, typescript-language-server |
| `scaffolding` | cookiecutter |

### Activation Scripts

**LM Studio app bundle** — `modules/darwin/configuration.nix` overrides the default `system.activationScripts.applications` to copy the LM Studio app bundle from the Nix store to `/Applications/LM Studio.app` using `ditto`, then runs `lsregister` to register it with macOS LaunchServices. This is required because macOS cannot reliably discover symlinked app bundles in `/Applications`.

**Local AI directories** — `modules/darwin/local-ai.nix` defines a custom `system.activationScripts.localAiDirs` that creates log and data directories under `~/Library/Logs/local-ai/` and `~/Library/Application Support/local-ai/`, then chowns them to the user.

---

## Local AI Services

All services run as launchd user agents under `org.nixos.*`. Managed in `modules/darwin/local-ai.nix`.

| Service | Address | Default State | Toggle |
|---|---|---|---|
| Qdrant | `127.0.0.1:6333` (HTTP), `:6334` (gRPC) | **Enabled** | always on |
| Ollama | `127.0.0.1:11434` | **Disabled** | `enableOllama = true` in `local-ai.nix` |
| LiteLLM | `127.0.0.1:4000` | **Disabled** | `enableLitellm = true` in `local-ai.nix` |

### Qdrant

- **Config:** `/etc/local-ai/qdrant.yaml`
- **Data:** `~/Library/Application Support/local-ai/qdrant/`
- **Working dir:** `~/Library/Application Support/local-ai/` (parent dir avoids relative path issues)
- **Stdout log:** `~/Library/Logs/local-ai/qdrant.log`
- **Stderr log:** `~/Library/Logs/local-ai/qdrant.err`

### Ollama (when enabled)

- **Models:** `~/Library/Application Support/local-ai/ollama/`
- **Stdout log:** `~/Library/Logs/local-ai/ollama.log`
- **Stderr log:** `~/Library/Logs/local-ai/ollama.err`

To enable Ollama: set `enableOllama = true` in `modules/darwin/local-ai.nix`, then rebuild.

### LiteLLM Proxy Gateway

- **Address:** `127.0.0.1:4000`
- **Config:** generated at Nix build time (embedded in store)
- **Stdout log:** `~/Library/Logs/local-ai/litellm.log`
- **Stderr log:** `~/Library/Logs/local-ai/litellm.err`

LiteLLM acts as an OpenAI-compatible proxy between opencode and LM Studio. Opencode sends requests to `localhost:4000`, LiteLLM routes them to LM Studio on `localhost:1234`. To enable: set `enableLitellm = true` in `modules/darwin/local-ai.nix`, then rebuild.

Verify with:
```bash
curl localhost:4000/v1/models
```

### Check Service Status

```bash
launchctl print gui/$(id -u)/org.nixos.qdrant
launchctl print gui/$(id -u)/org.nixos.ollama
```

---

## Opencode Environment

The full opencode configuration is generated declaratively at build time and managed as a Home Manager file at `~/.config/opencode/`.

### How It Works

```
models.nix + agent-defs/ + mcpServers + skills + commands
       ↓
  mkOpencodeEnv  (modules/opencode/default.nix)
       ↓
  opencode-env (Nix derivation: opencode.json + agents/ + skills/ + commands/)
       ↓
  openspecOpencodeAssets overlay (OpenSpec commands + skills added on top)
       ↓
  home.file.".config/opencode"   ←  ~/.config/opencode/
```

### Models

Defined in `modules/home/opencode/models.nix`. Each model has a `role`:

| Role | Effect |
|---|---|
| `"primary"` | Sets `model` in opencode.json |
| `"small"` | Sets `small_model` in opencode.json |
| `"available"` | Visible to opencode but not a default |

Providers:

| Provider | npm | baseURL |
|---|---|---|
| LM Studio (via LiteLLM) | `@ai-sdk/openai-compatible` | `http://127.0.0.1:4000/v1` |

Current model assignments:

| Model | Provider | Role |
|---|---|---|
| qwen3.6-35b | lmstudio | primary |
| qwen3-coder | lmstudio | available |

### MCP Servers

| Name | Binary | Purpose |
|---|---|---|
| `cq` | `cq mcp` (built from source) | Shared agent learning memory (SQLite) |
| `qdrant` | `mcp-server-qdrant` (pre-built venv) | Semantic memory via Qdrant vector DB |

The qdrant MCP server uses a pre-built Python venv (`qdrantMcpEnv`) built at Nix evaluation time to eliminate per-session PyPI downloads. The venv is pinned to nixpkgs Python and added to `home.packages` to keep the store path GC-rooted.

Environment variables for the qdrant MCP:

| Variable | Value |
|---|---|
| `QDRANT_URL` | `http://127.0.0.1:6333` |
| `COLLECTION_NAME` | `opencode-memory` |
| `EMBEDDING_MODEL` | `sentence-transformers/all-MiniLM-L6-v2` |

### Agents

10 agents defined in `modules/home/opencode/agent-defs/`:

| Agent | Mode | Temperature | Purpose |
|---|---|---|---|
| `project_lead` | primary | 0.1 | Plans, delegates, synthesizes. Never writes code. |
| `build` | primary | 0.2 | Default implementation agent. |
| `architect` | subagent | 0.1 | Design and architecture decisions. |
| `developer` | subagent | 0.2 | Feature implementation. |
| `qa_engineer` | subagent | 0.05 | Testing and quality certification. |
| `security_engineer` | subagent | 0.05 | Security review. |
| `technical_writer` | subagent | 0.2 | Documentation. |
| `devops_engineer` | subagent | 0.2 | Infrastructure and CI/CD. |
| `product_manager` | subagent | 0.1 | Requirements and user stories. |
| `ux_designer` | subagent | 0.35 | UX and accessibility. |

Agent definitions are validated at Nix evaluation time — missing required fields (`description`, `mode`, `temperature`, `permission`, `body`) or invalid `mode` values cause a build failure immediately.

### Skills

Installed to `~/.config/opencode/skills/`:

| Skill pack | Contents |
|---|---|
| `cq` | CQ protocol (agent learning memory) |
| `qdrant-*` (8 skills) | Qdrant clients, scaling, performance, search quality, monitoring, deployment, model migration, version upgrade |
| `openspec-*` (5 skills) | propose, apply, explore, sync, archive |

The `skills.paths` config in `opencode.json` is set explicitly to `~/.config/opencode/skills` to ensure deterministic discovery independent of opencode default scan paths.

### OpenSpec

OpenSpec CLI assets (commands + skills) are generated during the Nix build from the upstream `openspec` flake input — no `openspec init` or network call is needed at runtime.

To use OpenSpec-driven workflows in a project repository, run `openspec init` once in that repo's root to create `.openspec.yaml`.

Commands generated: `opsx-propose`, `opsx-explore`, `opsx-apply`, `opsx-sync`, `opsx-archive`.

### CQ

CQ (`cq`) provides a shared SQLite-backed knowledge database for agents. The binary is built from source via `modules/home/opencode/pkgs/cq.nix`.

| Setting | Value |
|---|---|
| Source | `mozilla-ai/cq` rev `cli/v0.11.0` |
| DB path | `~/.local/share/cq/knowledge.db` |
| Shell completion | Auto-loaded via `source <(cq completion zsh)` in `.zshrc` |
| MCP command | `cq mcp` (stdio) |

---

## Environment Variables

Set in `modules/home/home.nix` via `home.sessionVariables`:

| Variable | Value | Purpose |
|---|---|---|
| `CQ_LOCAL_DB_PATH` | `~/.local/share/cq/knowledge.db` | Shared DB path used by both shell and cq MCP server |
| `OPENCODE_ENABLE_EXA` | `"1"` | Enables Exa web search integration in opencode. Set to `""` or remove to disable. |

---

## Ownership Guide

When you need to change something, edit the file that owns it:

| What to change | File |
|---|---|
| Flake inputs, host wiring | `flake.nix` |
| System packages | `modules/darwin/packages.nix` |
| macOS activation (apps, directories) | `modules/darwin/configuration.nix` |
| Qdrant / Ollama / LiteLLM services | `modules/darwin/local-ai.nix` |
| LiteLLM proxy packaging + config | `modules/darwin/litellm-proxy/default.nix` |
| Git, zsh, env vars, user baseline | `modules/home/home.nix` |
| User-level packages | `modules/home/packages.nix` |
| Opencode models | `modules/home/opencode/models.nix` |
| Opencode MCP, skills, commands wiring | `modules/home/opencode/default.nix` |
| Agent definitions | `modules/home/opencode/agent-defs/<name>.nix` |
| Shared agent fields / templates | `modules/home/opencode/agent-defs/common.nix` |
| opencode.json builder internals | `modules/opencode/lib/config.nix` |
| Agent .md renderer / permissionOrder | `modules/opencode/lib/agents.nix` |

---

## Troubleshooting

### App not found in Spotlight after rebuild

macOS requires real app bundles in `/Applications`. Symlinks are not reliably discovered by LaunchServices.

The activation script copies the app with `ditto` and registers it with `lsregister`. If an app is still missing after rebuild, re-run:

```bash
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/LM Studio.app"
```

### qdrant MCP shows ENOENT in opencode

Trigger: `ENOENT: no such file or directory, posix_spawn '/nix/store/.../qdrant-mcp-env/bin/...'`

The qdrant MCP Python interpreter or entrypoint path no longer exists in the store. Checklist:

1. Check if the qdrant MCP env was garbage collected:
   ```bash
   p=$(jq -r '.mcp.qdrant.command[0]' ~/.config/opencode/opencode.json)
   ls -la "$p"
   ```
2. If missing, rebuild to restore the GC root:
   ```bash
   sudo darwin-rebuild switch --flake .#mac-studio
   ```
3. Fully quit and restart opencode after rebuild (running sessions keep stale in-memory config).

Root cause: if the venv derivation path embedded in `opencode.json` is not GC-rooted via `home.packages`, Nix can garbage-collect it while config still references it. The current config pins `qdrantMcpEnv` in `home.packages` to prevent this.

> **Do not revert the MCP command from `mcp-server-qdrant` back to `python -m mcp_server_qdrant`** — the package has no `__main__` and will fail to start even with a valid interpreter.

### qdrant database service crashing on startup

Check the error log:

```bash
tail -n 50 ~/Library/Logs/local-ai/qdrant.err
```

Common cause: `WorkingDirectory` pointed inside the storage path, causing qdrant to try creating `./snapshots/tmp` relative to a read-only Nix store path. The current config sets `WorkingDirectory` to the parent directory (`local-ai/`), not the storage path itself.

### opencode skills not visible

Skills are indexed at startup. After any rebuild:

1. Quit all opencode processes.
2. Start a fresh opencode session.
3. Verify:
   ```bash
   opencode debug skill | rg qdrant-
   ```

### Nix evaluation warning about `builtins.derivation` context

This warning is benign and comes from the upstream `openspec` flake. It does not affect correctness.

### New .nix files not found during evaluation

Nix flakes only see files tracked by Git. After creating a new `.nix` file:

```bash
git add <file>
nix build .#darwinConfigurations.mac-studio.system --dry-run
```
