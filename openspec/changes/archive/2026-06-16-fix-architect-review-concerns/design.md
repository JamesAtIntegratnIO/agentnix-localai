## Context

The nix-home flake (`/Users/jdreier/Projects/nix-home`) is a nix-darwin + Home Manager configuration for a Mac Studio (aarch64-darwin). It manages system packages, launchd agents (qdrant, ollama), and generates a complete opencode AI agent configuration directory (`~/.config/opencode/`) declaratively via Nix.

A thorough architectural review identified issues across the entire codebase: unsafe activation scripts, stale dependency pins, dead code, duplicate definitions, missing validation, and fragile build patterns. Additionally, the project_lead agent's edit permission is scoped to only 4 files (`PROJECT_STATE.md`, `TODO.md`, `QUESTIONS.md`, `GIT_WORKFLOW.md`) — it cannot write to `openspec/changes/` or `openspec/specs/`, which blocks the OpenSpec-driven workflow that the project_lead is expected to coordinate.

## Goals / Non-Goals

**Goals:**
- Fix all 3 critical and 5 high-severity issues from the review
- Fix the project_lead permission gap (P1) that blocks the OpenSpec workflow
- Address all 6 medium-severity issues
- Address all 5 low-severity suggestions
- Improve build reliability, security, and maintainability
- No behavioral changes to the user-facing configuration

**Non-Goals:**
- Adding new features, agents, models, or MCP servers
- Changing the opencode config schema or API
- Adding CI/CD pipelines (noted as M4 but out of scope for this change)
- Migrating from nix-darwin or Home Manager
- Upgrading flake input versions (M1 — documented but not implemented)

## Decisions

### Decision P1: Expand project_lead edit permissions to openspec/**
**Choice:** Add `"openspec/**"` to the project_lead's scoped edit permission list.

**Rationale:** The project_lead is the agent responsible for managing OpenSpec-driven changes — it creates proposals, tracks tasks, and archives completed changes. Without write access to `openspec/changes/`, it cannot fulfill this role. The glob pattern `openspec/**` covers both `openspec/changes/<name>/` (change artifacts) and `openspec/specs/` (capability specs).

**Alternatives considered:**
- Add each subdirectory individually (`openspec/changes/**`, `openspec/specs/**`) — rejected because `openspec/**` is simpler and covers both.
- Give project_lead unrestricted edit access — rejected because it violates least-privilege; the project_lead should only edit project management files.
- Create a separate agent for OpenSpec management — rejected because the project_lead is already the designated coordinator for all change management.

**Risk:** Expanding the edit scope increases the blast radius if the agent behaves unexpectedly. Mitigated by the project_lead's existing constraints (never write implementation code, delegate to other agents for code changes).

### Decision 1: Pin qdrantSkills to a specific commit (C1)
**Choice:** Pin to a specific commit SHA from the `qdrant/skills` repo instead of `main`.

**Rationale:** `fetchFromGitHub` with a fixed hash and `main` branch will break on the next upstream commit. Pinning to a SHA makes the build deterministic and reproducible.

**Alternatives considered:**
- Use a tagged release — rejected because the qdrant/skills repo may not have stable tags.
- Fetch at evaluation time — rejected because it breaks Nix purity.

**Action:** Examine the current `flake.lock` or store path to extract the actual commit SHA that the current hash corresponds to, then use that SHA as the `rev`.

### Decision 2: Symlink-based app activation (C2)
**Choice:** Replace `rm -rf /Applications/Nix Apps` + `cp` with `ln -sfT` (symlink).

**Rationale:** Symlinks are atomic, idempotent, and don't destroy other files in the directory. This eliminates the data loss risk.

**Alternatives considered:**
- Only remove `LM Studio.app` specifically — acceptable but less clean than symlinks.
- Keep `cp -rL` — rejected because it's the source of the fragility.

### Decision 3: Remove litellm.nix (H1)
**Choice:** Delete `modules/darwin/pkgs/litellm.nix`.

**Rationale:** The file is never imported or used anywhere in the flake. It's dead code that will bit-rot. If litellm is needed in the future, it can be re-added with a proper toggle pattern (like `enableOllama`).

**Alternatives considered:**
- Wire it into packages.nix — rejected because there's no indication the user wants litellm.
- Keep it with a comment — rejected because it still creates maintenance burden.

### Decision 4: Single-source permissionOrder (H2)
**Choice:** Define `permissionOrder` once in `modules/opencode/lib/agents.nix` (the renderer) and export it so `modules/home/opencode/agent-defs/common.nix` can reference it for consistency.

**Rationale:** The renderer is the source of truth for output order. `common.nix`'s copy should mirror it, not be the authoritative version.

**Alternatives considered:**
- Move `permissionOrder` to `common.nix` and pass it to the renderer — rejected because the renderer is the output producer and should own the ordering.
- Remove the ordering entirely — rejected because deterministic output is important for reproducibility.

### Decision 5: Agent definition validation (H3)
**Choice:** Add `lib.assert` checks in `agent-defs/default.nix` that validate each agent has required fields (`description`, `mode`, `temperature`, `permission`, `body`) and that `mode` is either `"primary"` or `"subagent"`.

**Rationale:** Without validation, typos like `temerature` silently produce broken agents. Asserts fail at Nix evaluation time, which is the earliest possible feedback.

**Alternatives considered:**
- Use `lib.mkOption` schema — rejected because agent defs are plain attrsets, not HM options.
- Runtime validation — rejected because Nix evaluation-time asserts are cheaper and catch issues earlier.

### Decision 6: Pre-build uvx environment for qdrant MCP (H4)
**Choice:** Create a Nix derivation that builds a uv virtual environment with `mcp-server-qdrant` pre-resolved and cached, then use that environment's `uvx` binary instead of the system `uv` package.

**Rationale:** Eliminates per-session PyPI resolution (startup latency) and network dependency (reliability). The uvx invocation becomes a local filesystem operation.

**Alternatives considered:**
- Use `pkgs.python3.withPackages` — rejected because `mcp-server-qdrant` is a uv/PyPI package, not a nixpkgs package.
- Accept the latency — rejected because it degrades UX noticeably on every MCP session start.

### Decision 7: Parameterize transformCqCommand (H5)
**Choice:** Convert `transformCqCommand` from a function of one argument (`file`) to a function of an attrset (`{ file, agent }`), passing the agent name as an `awk -v` variable.

**Rationale:** The current hardcoded `agent: build` means every command gets the same agent assignment. Parameterizing makes it reusable for future commands with different agent targets.

**Alternatives considered:**
- Write separate transform functions per command — rejected because it violates DRY.
- Use sed instead of awk — rejected because awk is more precise for frontmatter manipulation.

### Decision 8: Separate Qdrant WorkingDirectory (M3)
**Choice:** Set `WorkingDirectory` to the parent directory (`/Users/${username}/Library/Application Support/local-ai/`) instead of the storage path itself.

**Rationale:** Running with CWD inside the storage directory creates fragile relative path resolution. The parent directory is a neutral working directory.

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| project_lead editing openspec/ could cause conflicts if multiple agents write simultaneously | The project_lead is the sole coordinator; it delegates to other agents and consolidates their output |
| Symlink in `/Applications/Nix Apps/` may not work with macOS Gatekeeper | Test on target machine; fallback to `cp` if notarization issues arise |
| Pre-built uvx environment increases derivation size | `mcp-server-qdrant` is small; the cache benefit outweighs the store size |
| Removing `litellm.nix` may surprise future user | Note in commit message; the file can always be recovered from git history |
| Agent validation asserts may break existing agents if they have subtle issues | Review each agent definition manually before applying |
| Parameterized `transformCqCommand` changes the Nix API | Only used internally within `default.nix`; no external consumers |

## Migration Plan

1. Create the change (this OpenSpec artifact)
2. Implement all tasks sequentially by severity (P1 first, then critical → high → medium → low)
3. Run `darwin-rebuild build --flake .#mac-studio` to verify the build succeeds
4. Run `darwin-rebuild switch --flake .#mac-studio` to apply
5. Verify: qdrant launches, opencode loads, project_lead can write to openspec/, `nix flake update` works without hash mismatch

## Open Questions

1. **Should `litellm.nix` be kept with a toggle?** The file is well-implemented but unused. If the user intends to use litellm, it should be wired up with an `enableLitellm` flag rather than deleted.
2. **Should M6 (dual-primary-agent) be investigated with opencode docs?** We don't know if opencode supports multiple `primary` mode agents. This should be verified before deciding to consolidate.
3. **Should M1 (update cadence documentation) be addressed?** Noted but deferred — the user should decide how often to update `nixpkgs-unstable`.
