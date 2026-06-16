## 1. Agent Permission Fix (P1)

- [x] 1.1 Add `"openspec/**"` to the project_lead's scoped edit permission list in `modules/home/opencode/agent-defs/project_lead.nix` — this allows the project_lead to create and update OpenSpec change artifacts (proposal.md, design.md, tasks.md, specs/). Also update the "Project State Files" section in the project_lead's body text to list `openspec/changes/` as an editable path.

## 2. Critical Fixes (C1–C3)

- [x] 2.1 Pin `qdrantSkills` to a specific commit SHA in `modules/home/opencode/default.nix` — extract the actual commit from the current store path or `flake.lock`, replace `rev = "main"` with the SHA, keep the existing hash.
- [x] 2.2 Replace `rm -rf /Applications/Nix Apps` with symlink-based approach in `modules/darwin/configuration.nix` — use `ln -sfT` instead of `rm -rf` + `cp -rL`, keep the directory creation but remove the destructive removal.
- [x] 2.3 Add ollama models directory to activation script in `modules/darwin/local-ai.nix` — add `"/Users/${username}/Library/Application Support/local-ai/ollama"` to the `mkdir -p` command and to the `chown` paths.

## 3. High-Severity Fixes (H1–H5)

- [x] 3.1 Remove dead `modules/darwin/pkgs/litellm.nix` — delete the file since it is never imported or used by any other module in the flake.
- [x] 3.2 Single-source `permissionOrder` — move `permissionOrder` from `common.nix` to `modules/opencode/lib/agents.nix` (the renderer), export it, and have `common.nix` reference it or remove its duplicate. Ensure `lsp` is included in the renderer's list.
- [x] 3.3 Add agent definition validation in `modules/home/opencode/agent-defs/default.nix` — create a `validateAgent` function using `lib.assert` that checks for required fields (`description`, `mode`, `temperature`, `permission`, `body`) and validates `mode` is `"primary"` or `"subagent"`, then apply it to all 10 agents.
- [x] 3.4 Pre-build uv environment for qdrant MCP in `modules/home/opencode/default.nix` — create a Nix derivation that builds a uv virtual environment with `mcp-server-qdrant` and its dependencies cached, then update the qdrant MCP server config to use this environment's `uvx` binary.
- [x] 3.5 Parameterize `transformCqCommand` in `modules/home/opencode/default.nix` — convert from `file: ...` to `{ file, agent }: ...`, pass agent name via `awk -v`, update the two call sites (`cq-reflect` and `cq-status`) to pass their respective agent names.

## 4. Medium-Severity Fixes (M3, M5, M6)

- [x] 4.1 Separate Qdrant `WorkingDirectory` from `storage_path` in `modules/darwin/local-ai.nix` — change `WorkingDirectory` from `${qdrantDataDir}` to `"/Users/${username}/Library/Application Support/local-ai/"`.
- [x] 4.2 Add inline comments for session variables in `modules/home/home.nix` — document `OPENCODE_ENABLE_EXA` (what it does, how to disable) and `CQ_LOCAL_DB_PATH` (shared with cq MCP server).
- [x] 4.3 Document dual-primary-agent behavior — add a comment in both `build.nix` and `project_lead.nix` noting that both agents have `mode = "primary"`, and verify against opencode documentation whether this is supported. If not supported, consolidate to a single primary.

## 5. Low-Severity Improvements (L1, L2, L3, L4, L5)

- [x] 5.1 Extract "Project Rule Awareness" section into `common.nix` — create a `projectRuleAwareness` string in `common.nix` containing the 6-line duplicated section, then have each agent's `body` concatenate it. This reduces 60 lines of duplication to 1 definition + 10 references.
- [x] 5.2 Add `.gitignore` entry for `result/` — create or update `.gitignore` in the repository root to include `result/` since it is a Nix store symlink.
- [x] 5.3 Verify `lsp` is in the renderer's `permissionOrder` — confirm that `modules/opencode/lib/agents.nix` includes `"lsp"` in its `permissionOrder` list (this is covered by 3.2 but should be verified as a separate check).
- [x] 5.4 Consider pre-built `cq` binary — add a comment in `modules/home/opencode/pkgs/cq.nix` noting that the Go source build adds rebuild time, and suggest that a pre-built binary from a GitHub release could be used as an alternative (defer implementation).
- [x] 5.5 Add `lib.types` annotations to `mkOpencodeEnv` — add type annotations to the parameters of `mkOpencodeEnv` in `modules/opencode/default.nix` using `lib.types.attrs`, `lib.types.attrsOf`, etc. (defer if it introduces complexity).

## 6. Verification

- [x] 6.1 Run `nix build .#darwinConfigurations.mac-studio.system` to verify the flake builds without errors.
- [x] 6.2 Run `darwin-rebuild build --flake .#mac-studio` to verify the darwin build succeeds.
- [x] 6.3 Run `nix flake update` to verify that `qdrantSkills` no longer breaks on upstream changes (confirm the hash matches the pinned commit).
- [x] 6.4 Verify that `git status` does not show `result/` as an untracked file.
- [x] 6.5 Verify that all 10 agent `.md` files are generated correctly with proper frontmatter ordering (including `lsp` in the permission block).
- [x] 6.6 Verify that the project_lead agent definition includes `"openspec/**"` in its scoped edit permission list.
