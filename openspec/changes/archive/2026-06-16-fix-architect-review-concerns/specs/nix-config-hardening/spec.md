## ADDED Requirements

### Requirement: GitHub dependencies are pinned to specific commits
All `fetchFromGitHub` calls in the flake MUST pin to a specific commit SHA or version tag, never to a mutable branch like `main` or `master`. The `rev` field MUST be a stable reference that does not change without an explicit `nix flake update`.

#### Scenario: qdrantSkills uses a pinned commit
- **WHEN** the flake is evaluated
- **THEN** `qdrantSkills` in `modules/home/opencode/default.nix` references a specific commit SHA (not `main`)
- **AND** the hash matches the pinned commit

#### Scenario: cq uses a pinned version tag
- **WHEN** the flake is evaluated
- **THEN** `cq` in `modules/home/opencode/default.nix` references a version tag (e.g., `cli/v0.11.0`)
- **AND** the hash matches the tagged revision

### Requirement: Activation scripts are idempotent and safe
All darwin activation scripts MUST be idempotent — running them multiple times must produce the same result without data loss. Directory cleanup MUST NOT use `rm -rf` on directories that may contain user-managed content.

#### Scenario: LM Studio app is installed via symlink
- **WHEN** the darwin activation script runs
- **THEN** `/Applications/Nix Apps/LM Studio.app` is a symlink to the Nix store path
- **AND** no other files in `/Applications/Nix Apps/` are affected
- **AND** re-running the activation produces the same symlink

#### Scenario: Local AI directories are created with correct ownership
- **WHEN** the darwin activation script `localAiDirs` runs
- **THEN** `/Users/${username}/Library/Logs/local-ai/` exists and is owned by `${username}:staff`
- **AND** `/Users/${username}/Library/Application Support/local-ai/qdrant` exists and is owned by `${username}:staff`
- **AND** `/Users/${username}/Library/Application Support/local-ai/ollama` exists and is owned by `${username}:staff`

### Requirement: No dead code in the flake
All files under `modules/` MUST be referenced by at least one other file in the flake (imported, included, or otherwise used). Files that are not imported by any other module MUST be removed or wired into the configuration.

#### Scenario: litellm.nix is either imported or absent
- **WHEN** the flake is evaluated
- **THEN** `modules/darwin/pkgs/litellm.nix` either is imported by `modules/darwin/packages.nix` or does not exist
- **AND** no orphaned `.nix` files exist under `modules/darwin/pkgs/`

### Requirement: Permission order is single-sourced
The `permissionOrder` list used for rendering agent frontmatter MUST be defined exactly once in the codebase. All references to permission ordering MUST derive from this single definition.

#### Scenario: lsp permission renders in deterministic position
- **WHEN** an agent with an `lsp` permission is rendered
- **THEN** the `lsp` key appears at a deterministic position in the frontmatter
- **AND** the position is consistent across all builds

#### Scenario: permissionOrder is defined in one location
- **WHEN** the codebase is searched for `permissionOrder`
- **THEN** exactly one definition exists in `modules/opencode/lib/agents.nix`
- **AND** `modules/home/opencode/agent-defs/common.nix` references or mirrors this definition

### Requirement: Agent definitions are validated at evaluation time
Every agent definition in `modules/home/opencode/agent-defs/` MUST pass compile-time validation that checks:
- The agent has all required fields: `description`, `mode`, `temperature`, `permission`, `body`
- The `mode` field is either `"primary"` or `"subagent"`

#### Scenario: Valid agent passes validation
- **WHEN** the flake is evaluated
- **THEN** all 10 agent definitions pass validation without errors

#### Scenario: Missing required field causes evaluation error
- **WHEN** an agent definition omits a required field (e.g., `temperature`)
- **THEN** Nix evaluation fails with a clear assertion message identifying the agent name and missing field

#### Scenario: Invalid mode value causes evaluation error
- **WHEN** an agent definition has `mode = "invalid"`
- **THEN** Nix evaluation fails with an assertion message stating mode must be `"primary"` or `"subagent"`

### Requirement: MCP server dependencies are pre-resolved
The `mcp-server-qdrant` MCP server MUST use a pre-built uv virtual environment with all dependencies cached, eliminating per-session PyPI resolution and network dependency.

#### Scenario: qdrant MCP starts without network access
- **WHEN** opencode starts the qdrant MCP server
- **THEN** the server starts using a pre-resolved uv environment
- **AND** no network requests to PyPI are made during startup

#### Scenario: qdrant MCP uses a vendored environment
- **WHEN** the flake is built
- **THEN** a uv virtual environment derivation is created containing `mcp-server-qdrant` and all its transitive dependencies
- **AND** the MCP server command references this environment

### Requirement: CQ command transformation is parameterized
The `transformCqCommand` function MUST accept an `agent` parameter to specify which agent the transformed command should be assigned to, instead of hardcoding `agent: build`.

#### Scenario: transformCqCommand accepts agent parameter
- **WHEN** `transformCqCommand` is called with `{ file, agent }`
- **THEN** the output frontmatter contains `agent: <agent>` where `<agent>` matches the passed parameter

#### Scenario: Existing cq commands use correct agent names
- **WHEN** the flake is evaluated
- **THEN** `cq-reflect` and `cq-status` commands are generated with appropriate agent assignments

### Requirement: Qdrant working directory is separate from storage path
The Qdrant launchd agent MUST use a working directory that is the parent of the storage path, not the storage path itself, to avoid fragile relative path resolution.

#### Scenario: Qdrant has a neutral working directory
- **WHEN** the qdrant launchd agent starts
- **THEN** `WorkingDirectory` is set to `/Users/${username}/Library/Application Support/local-ai/`
- **AND** `storage_path` in the config is set to `/Users/${username}/Library/Application Support/local-ai/qdrant`

### Requirement: Environment variables are documented
All `home.sessionVariables` in the Home Manager configuration MUST have inline comments explaining their purpose, how to disable them (if applicable), and what version of opencode introduced them.

#### Scenario: OPENCODE_ENABLE_EXA is documented
- **WHEN** `modules/home/home.nix` is read
- **THEN** the `OPENCODE_ENABLE_EXA` variable has an inline comment explaining its purpose

#### Scenario: CQ_LOCAL_DB_PATH is documented
- **WHEN** `modules/home/home.nix` is read
- **THEN** the `CQ_LOCAL_DB_PATH` variable has an inline comment explaining its purpose and that it is shared with the cq MCP server

### Requirement: Duplicate code is eliminated
Identical or near-identical code blocks MUST be extracted into shared templates. Specifically, the "Project Rule Awareness" section (6 lines) that is duplicated verbatim across all 10 agent definitions MUST be consolidated into a single template in `common.nix`.

#### Scenario: Project Rule Awareness is defined once
- **WHEN** the codebase is searched for the string "Project Rule Awareness"
- **THEN** it appears exactly once in `modules/home/opencode/agent-defs/common.nix`
- **AND** each agent's `body` field concatenates `common.projectRuleAwareness` (or equivalent)

#### Scenario: Agent bodies are generated correctly
- **WHEN** the flake is evaluated
- **THEN** all 10 agent `.md` files contain the "Project Rule Awareness" section
- **AND** the content matches the template in `common.nix`

### Requirement: Nix store symlinks are gitignored
The `result/` symlink (produced by `nix build`) MUST be listed in `.gitignore` to prevent it from being committed to version control.

#### Scenario: result/ is gitignored
- **WHEN** `git status` is run in the repository root
- **THEN** `result/` does not appear as an untracked file

### Requirement: project_lead has write access to OpenSpec directories
The project_lead agent's edit permission MUST include the `openspec/` directory so it can create, update, and archive OpenSpec change artifacts. The scoped edit permission list MUST include `"openspec/**"` as a pattern.

#### Scenario: project_lead can write proposal.md
- **WHEN** the project_lead agent needs to create a new OpenSpec change
- **THEN** it can write to `openspec/changes/<change-name>/proposal.md`

#### Scenario: project_lead can write tasks.md
- **WHEN** the project_lead agent needs to update task progress
- **THEN** it can write to `openspec/changes/<change-name>/tasks.md`

#### Scenario: project_lead can write spec files
- **WHEN** the project_lead agent needs to update capability specifications
- **THEN** it can write to `openspec/changes/<change-name>/specs/**/*.md`

#### Scenario: project_lead edit permission includes openspec glob
- **WHEN** `modules/home/opencode/agent-defs/project_lead.nix` is read
- **THEN** the scoped edit permission list contains `"openspec/**"`
