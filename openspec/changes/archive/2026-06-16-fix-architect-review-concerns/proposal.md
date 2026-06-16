## Why

An architectural review identified 3 critical, 5 high, 6 medium, and 5 low-severity concerns across the nix-home flake. These range from build-breaking issues (stale GitHub hash, unsafe directory removal) to maintainability gaps (dead code, duplicate definitions, missing validation). Additionally, the project_lead agent lacks write permission to the `openspec/` directory, preventing it from creating and managing OpenSpec change artifacts — a fundamental gap in the agent delegation workflow. Left unfixed, these risks cause build failures, data loss, silent misconfiguration, and broken agent workflows.

## What Changes

- **P1 — Add `openspec/**` to project_lead edit permissions** so the agent can create and update OpenSpec change artifacts (proposal.md, design.md, tasks.md, specs/). This is a blocking gap: the project_lead cannot fulfill its role of managing OpenSpec-driven changes without this permission.
- **C1 — Pin `qdrantSkills` to a specific commit SHA** instead of `main` with a stale hash, preventing build breakage on upstream updates.
- **C2 — Replace `rm -rf /Applications/Nix Apps` with a symlink-based approach** in the darwin activation script, eliminating data loss risk.
- **C3 — Add ollama models directory** to the local-ai activation script so the service starts correctly when `enableOllama = true`.
- **H1 — Remove dead `litellm.nix`** (or wire it up with a toggle if intentionally kept).
- **H2 — Single-source `permissionOrder`** across `common.nix` and `lib/agents.nix` to fix non-deterministic `lsp` permission rendering.
- **H3 — Add compile-time agent definition validation** in `agent-defs/default.nix` to catch missing/misnamed fields.
- **H4 — Pre-build a uv environment for `mcp-server-qdrant`** to eliminate per-session PyPI resolution latency and network dependency.
- **H5 — Parameterize `transformCqCommand`** to accept an `agent` argument instead of hardcoding `build`.
- **M3 — Separate Qdrant `WorkingDirectory` from `storage_path`** to avoid fragile relative path resolution.
- **M5 — Add documentation comments** for `OPENCODE_ENABLE_EXA` and other undocumented env vars.
- **M6 — Document dual-primary-agent behavior** or consolidate to a single primary.
- **L1 — Extract duplicated "Project Rule Awareness" section** into `common.nix` template.
- **L2 — Add `.gitignore` entry** for `result/` symlink.

## Capabilities

### New Capabilities
- `nix-config-hardening`: Systematic fixes for critical and high-severity architectural concerns in the nix-darwin + Home Manager flake configuration.
- `agent-permission-scope`: Ensure the project_lead agent has write access to OpenSpec change directories so it can fulfill its coordination role.

### Modified Capabilities
- *(none — this is a maintenance/hardening change, not a new feature)*

## Impact

- **Modified files:** `modules/darwin/configuration.nix`, `modules/darwin/local-ai.nix`, `modules/darwin/pkgs/litellm.nix` (deletion), `modules/home/opencode/default.nix`, `modules/home/opencode/agent-defs/common.nix`, `modules/home/opencode/agent-defs/default.nix`, `modules/home/opencode/agent-defs/project_lead.nix`, `modules/opencode/lib/agents.nix`, `modules/home/home.nix`, potentially `modules/home/packages.nix` (uvx env).
- **No spec changes** — behavior requirements remain the same; only implementation quality improves.
- **No API changes** — all changes are internal to the Nix build system.
- **Agent behavior change:** project_lead gains write access to `openspec/changes/` and `openspec/specs/` paths.
- **Rebuild required** — `darwin-rebuild switch --flake .#mac-studio` after applying.
