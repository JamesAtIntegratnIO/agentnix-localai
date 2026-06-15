{ pkgs, username, lib, inputs, ... }:
let
  mkOpencodeEnv = (import ../../opencode { inherit pkgs lib; }).mkOpencodeEnv;
  openspec = inputs.openspec.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # cq source — skill files, commands, and MCP binary all come from the same pin.
  cqSrc = pkgs.fetchFromGitHub {
    owner = "mozilla-ai";
    repo  = "cq";
    rev   = "cli/v0.11.0";
    hash  = "sha256-2bv1FgrbJlb+lBFgJm8izDu6hQf8UwiJxdzua9Xoi8k=";
  };

  # Qdrant agent skills — 8 hub skills teaching agents when/why/how to use Qdrant.
  qdrantSkills = pkgs.fetchFromGitHub {
    owner = "qdrant";
    repo  = "skills";
    rev   = "main";
    hash  = "sha256-ZM7BC8uHPzAGwUa1niV7TEuUHUAgaJB8Eska9ufljSM=";
  };

  # cq binary used by shell completion and cq MCP server.
  cq = pkgs.callPackage ./pkgs/cq.nix {};

  # Strip the `name:` frontmatter field (opencode uses filename as the name)
  # and inject `agent: build` as the last frontmatter key.
  transformCqCommand = file:
    pkgs.runCommand "cq-cmd-${builtins.baseNameOf file}" {
      nativeBuildInputs = [ pkgs.gawk ];
    } ''
      awk '
        BEGIN { fm=1 }
        NR==1 { print; next }
        fm && /^---$/ { print "agent: build"; print; fm=0; next }
        fm && /^name:/ { next }
        { print }
      ' ${file} > $out
    '';

  opencodeEnv = mkOpencodeEnv {
    models     = import ./models.nix;
    agents     = import ./agent-defs {};

    mcpServers = {
      cq = {
        type    = "local";
        enabled = true;
        command = [ "${cq}/bin/cq" "mcp" ];
        environment = {
          CQ_LOCAL_DB_PATH = "/Users/${username}/.local/share/cq/knowledge.db";
        };
      };
      # mcp-server-qdrant: semantic memory — store/retrieve information via Qdrant.
      qdrant = {
        type    = "local";
        enabled = true;
        command = [ "${pkgs.uv}/bin/uvx" "mcp-server-qdrant" ];
        environment = {
          QDRANT_URL      = "http://127.0.0.1:6333";
          COLLECTION_NAME = "opencode-memory";
          EMBEDDING_MODEL = "sentence-transformers/all-MiniLM-L6-v2";
        };
      };
    };

    skills = {
      "cq/SKILL.md"                     = "${cqSrc}/plugins/cq/skills/cq/SKILL.md";
      "qdrant-clients-sdk"              = "${qdrantSkills}/skills/qdrant-clients-sdk";
      "qdrant-scaling"                  = "${qdrantSkills}/skills/qdrant-scaling";
      "qdrant-performance-optimization" = "${qdrantSkills}/skills/qdrant-performance-optimization";
      "qdrant-search-quality"           = "${qdrantSkills}/skills/qdrant-search-quality";
      "qdrant-monitoring"               = "${qdrantSkills}/skills/qdrant-monitoring";
      "qdrant-deployment-options"       = "${qdrantSkills}/skills/qdrant-deployment-options";
      "qdrant-model-migration"          = "${qdrantSkills}/skills/qdrant-model-migration";
      "qdrant-version-upgrade"          = "${qdrantSkills}/skills/qdrant-version-upgrade";
    };

    commands = {
      "cq-reflect" = transformCqCommand "${cqSrc}/plugins/cq/commands/reflect.md";
      "cq-status"  = transformCqCommand "${cqSrc}/plugins/cq/commands/status.md";
    };

    agentsMd = ''
      <!-- cq:start -->
      ## CQ

      Before starting any implementation task, load the `cq` skill and follow its Core Protocol.
      <!-- cq:end -->

      <!-- qdrant:start -->
      ## Qdrant Memory

      Use the `qdrant` MCP server for semantic memory whenever context from prior tasks could help.
      At task start, retrieve relevant memory from Qdrant.
      Before finishing, write concise implementation notes and decisions back to Qdrant.
      <!-- qdrant:end -->

      <!-- openspec:start -->
      ## OpenSpec

      For non-trivial features or refactors, use OpenSpec to define scope and tasks before implementation.
      Prefer: `openspec init` (once per repo), `/opsx:propose <change>`, `/opsx:apply`, and `/opsx:archive`.
      Keep implementation aligned to the active OpenSpec artifacts.
      <!-- openspec:end -->
    '';
  };
in
{
  home.packages = [ pkgs.opencode cq openspec ];

  home.file.".config/opencode" = {
    source = opencodeEnv;
    recursive = true;
    force = true;
  };
}
