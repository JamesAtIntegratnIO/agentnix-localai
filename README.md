# nix-home

Flake-based macOS configuration for `mac-studio` using nix-darwin + Home Manager.

## Structure

```text
flake.nix                          # inputs, host wiring, nixpkgs config
modules/
  darwin/
    configuration.nix              # system config, Spotlight app sync
    packages.nix                   # all system packages (single callPackage source)
    local-ai.nix                   # local AI control plane (launchd services + configs)
    pkgs/
      cq.nix                       # custom derivation: mozilla-ai/cq CLI
      litellm.nix                  # custom derivation: LiteLLM proxy
  home/
    home.nix                       # Home Manager config (git, zsh, user packages)
    packages.nix                   # user-level packages
```

## Local AI stack

Always-on services bound to `127.0.0.1` only:

| Service  | Address                  | Purpose                          |
|----------|--------------------------|----------------------------------|
| Ollama   | `127.0.0.1:11434`        | Local LLM inference (Metal/GPU)  |
| Qdrant   | `127.0.0.1:6333`         | Vector store / RAG memory        |
| LiteLLM  | `127.0.0.1:4000/v1`      | OpenAI-compatible proxy          |

Model aliases (via LiteLLM):

| Alias          | Model                  |
|----------------|------------------------|
| `local-fast`   | qwen2.5-coder:14b      |
| `local-deep`   | qwen3-coder:30b        |
| `local-embed`  | nomic-embed-text       |

Every repo and agent uses:

```text
OPENAI_BASE_URL=http://127.0.0.1:4000/v1
OPENAI_API_KEY=sk-local-dev
```

Data persists at `/var/lib/local-ai/{ollama,qdrant,litellm,cq}`.

`cq` (mozilla-ai/cq) is installed as a CLI tool for agent learning memory. Its MCP server runs per-invocation via stdio — no daemon needed.

### Pull models (once after first apply)

```bash
ollama pull qwen2.5-coder:14b
ollama pull qwen3-coder:30b
ollama pull nomic-embed-text
```

## First-time bootstrap

```bash
cd /Users/jdreier/Projects/nix-home
sudo nix run github:lnl7/nix-darwin -- switch --flake .#mac-studio
```

## Apply updates

```bash
darwin-rebuild switch --flake .#mac-studio
```

## Update flake inputs

```bash
nix flake update && darwin-rebuild switch --flake .#mac-studio
```

## Customize

- Hostname/username → `flake.nix`
- System packages → `modules/darwin/packages.nix`
- AI model config → `modules/darwin/local-ai.nix`
- User packages → `modules/home/packages.nix`
- Shell/git config → `modules/home/home.nix`
- GUI apps (Spotlight) → `system.activationScripts.applications` in `modules/darwin/configuration.nix`
