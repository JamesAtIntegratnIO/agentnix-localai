# nix-home

Flake-based macOS configuration for **mac-studio** (Apple Silicon Mac Studio) using nix-darwin + Home Manager.

## What This Repo Does

It manages a personal macOS development machine across four layers:

```
┌─────────────────────────────────────────────────┐
│                  macOS Desktop                   │
│  (LM Studio UI, opencode CLI, terminal, apps)   │
└──────┬──────────────────────────┬────────────────┘
       │                          │
┌──────▼──────┐          ┌────────▼────────┐
│ nix-darwin  │          │ Home Manager    │
│ (system)    │          │ (user)          │
│             │          │                 │
│ • Host name │          │ • Git config    │
│ • Zsh       │          │ • Zsh aliases   │
│ • System pkgs│         │ • User packages │
│ • launchd   │          │ • opencode.json │
│             │          │ • hermes config │
└──────┬──────┘          └────────┬────────┘
       │                          │
       ▼                          ▼
┌─────────────────────────────────────────────────┐
│           Local AI Services (launchd)            │
│                                                  │
│  Qdrant  (vector DB, :6333)    ● Always on      │
│  Ollama  (inference, :11434)   ○ Disabled by def│
└─────────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────┐
│           Opencode AI Agent Stack                │
│                                                  │
│  opencode.json → models + agents + MCP + skills │
│  CQ (knowledge DB) ←→ Qdrant MCP (semantic mem) │
└─────────────────────────────────────────────────┘
```

## Quick Start

```bash
# Build without applying
nix build .#darwinConfigurations.mac-studio.system

# Apply changes
darwin-rebuild switch --flake .#mac-studio

# Update all flake inputs
nix flake update
darwin-rebuild switch --flake .#mac-studio
```

## Documentation

| File | Purpose |
|---|---|
| [ARCHITECTURE.md](./docs/ARCHITECTURE.md) | How the four layers fit together, data flow, module system |
| [CONVENTIONS.md](./docs/CONVENTIONS.md) | How to add packages, agents, services — the "how to work here" guide |
| [SERVICES.md](./docs/SERVICES.md) | Local AI services: Qdrant, Ollama — config, verify, troubleshoot |
| [OPENCODE.md](./docs/OPENCODE.md) | Opencode stack: models, agents, MCP servers, skills, OpenSpec |

## Ownership Guide

Use this as the source of truth when changing behavior:

| What it owns | File |
|---|---|
| Host wiring and flake inputs | `flake.nix` |
| System package set | `modules/darwin/packages.nix` |
| Local AI launchd / runtime config | `modules/darwin/local-ai.nix` |
| Home Manager baseline (git, zsh, user pkgs) | `modules/home/home.nix` |
| Generic user package groups | `modules/home/packages.nix` |
| Opencode stack & integrations | `modules/home/opencode/default.nix` |
| Opencode env builder internals | `modules/opencode/default.nix` |
