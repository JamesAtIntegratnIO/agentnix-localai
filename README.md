# agentnix-localai

Flake-based macOS configuration for mac-studio using nix-darwin + Home Manager.

## Current Architecture

```text
flake.nix
  Inputs: nixpkgs, nix-darwin, home-manager, openspec
  Wires both Darwin and Home Manager modules

modules/
  darwin/
    configuration.nix
      Host-level settings, system packages, Spotlight app sync
    packages.nix
      System package groups (includes qdrant, ollama, uv, etc.)
    local-ai.nix
      launchd user agents and local AI runtime config
      - qdrant enabled
      - ollama definition kept, disabled by default via toggle
    pkgs/
      litellm.nix

  home/
    home.nix
      Home Manager base config (git, zsh, user packages, env vars)
    packages.nix
      User package groups
    opencode/
      default.nix
        Owns opencode + cq + openspec integration
      models.nix
      agent-defs/
      pkgs/
        cq.nix

  opencode/
    default.nix
      mkOpencodeEnv builder for pure opencode config generation
    lib/
      config.nix
      agents.nix
```

## Local AI Runtime

Configured local services:

| Service | Address | Status | Notes |
|---|---|---|---|
| Qdrant | 127.0.0.1:6333 | Enabled | Launchd user agent with writable user-owned data dir |
| Ollama | 127.0.0.1:11434 | Disabled by default | Service block is preserved; toggle in local-ai.nix |

Qdrant data path:

- /Users/jdreier/Library/Application Support/local-ai/qdrant

Qdrant logs:

- /Users/jdreier/Library/Logs/local-ai/qdrant.log
- /Users/jdreier/Library/Logs/local-ai/qdrant.err

## Opencode Integration

Opencode configuration is generated declaratively and linked to:

- ~/.config/opencode

It includes:

- Model/provider config from modules/home/opencode/models.nix
- Agent definitions from modules/home/opencode/agent-defs
- MCP servers:
  - cq (local stdio MCP)
  - qdrant (via uvx mcp-server-qdrant)
- CQ commands and skill
- Qdrant skill pack
- OpenSpec commands and skills, generated during Nix build

### OpenSpec Behavior

OpenSpec command and skill assets are generated in Nix from the upstream OpenSpec package, then overlaid into the opencode env.

This means:

- No manual copy step is needed for opencode commands/skills
- Assets persist across rebuilds
- Generation avoids running openspec init inside the Nix sandbox

For repo workflow artifacts (outside of opencode command/skill registration), run openspec init once in each target repository when starting OpenSpec-driven work.

## Common Commands

First-time bootstrap:

```bash
cd /Users/jdreier/Projects/agentnix-localai
sudo nix run github:lnl7/nix-darwin -- switch --flake .#mac-studio
```

Apply changes:

```bash
darwin-rebuild switch --flake .#mac-studio
```

Build without switching:

```bash
nix build .#darwinConfigurations.mac-studio.system
```

Dry-run a system build:

```bash
nix build .#darwinConfigurations.mac-studio.system --dry-run
```

Update all flake inputs:

```bash
nix flake update
darwin-rebuild switch --flake .#mac-studio
```

## Ownership Guide

Use this as the source of truth when changing behavior:

- Host wiring and flake inputs: flake.nix
- System package set: modules/darwin/packages.nix
- Local AI launchd/runtime behavior: modules/darwin/local-ai.nix
- Home Manager baseline config: modules/home/home.nix
- Generic user packages: modules/home/packages.nix
- Opencode stack and integrations: modules/home/opencode/default.nix
- Opencode environment builder internals: modules/opencode/default.nix
