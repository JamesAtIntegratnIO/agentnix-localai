{ pkgs, username, lib, ... }:
let
  # Same source pin used by modules/darwin/pkgs/cq.nix — reuses the nix cache.
  cqSrc = pkgs.fetchFromGitHub {
    owner = "mozilla-ai";
    repo = "cq";
    rev = "cli/v0.11.0";
    hash = "sha256-2bv1FgrbJlb+lBFgJm8izDu6hQf8UwiJxdzua9Xoi8k=";
  };

  # Qdrant agent skills — 8 hub skills teaching agents when/why/how to use Qdrant.
  qdrantSkills = pkgs.fetchFromGitHub {
    owner = "qdrant";
    repo = "skills";
    rev = "main";
    hash = "sha256-ZM7BC8uHPzAGwUa1niV7TEuUHUAgaJB8Eska9ufljSM=";
  };

  # Build the cq binary (cached; same derivation as darwin/pkgs/cq.nix).
  cq = pkgs.callPackage ../../darwin/pkgs/cq.nix {};

  # Apply the opencode command transform:
  #   - Strip the `name:` frontmatter field (opencode uses filename as the name).
  #   - Add `agent: build` as the last frontmatter key.
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

  opencodeConfig = import ./opencode-config.nix {
    inherit pkgs username cq;
  };

  agentsModule = import ./agents.nix { inherit pkgs lib; };
in
lib.mkMerge [
  {
    # Global opencode config — local models via LM Studio and Ollama.
    home.file.".config/opencode/opencode.json" = {
      text = builtins.toJSON opencodeConfig;
    };

    # cq plugin files — skill protocol loaded by agents, slash-commands for the UI.
    home.file.".config/opencode/skills/cq/SKILL.md".source =
      "${cqSrc}/plugins/cq/skills/cq/SKILL.md";

    # Qdrant hub skills — teach agents scaling, performance, search quality, etc.
    home.file.".config/opencode/skills/qdrant-clients-sdk".source       = "${qdrantSkills}/skills/qdrant-clients-sdk";
    home.file.".config/opencode/skills/qdrant-scaling".source           = "${qdrantSkills}/skills/qdrant-scaling";
    home.file.".config/opencode/skills/qdrant-performance-optimization".source = "${qdrantSkills}/skills/qdrant-performance-optimization";
    home.file.".config/opencode/skills/qdrant-search-quality".source    = "${qdrantSkills}/skills/qdrant-search-quality";
    home.file.".config/opencode/skills/qdrant-monitoring".source        = "${qdrantSkills}/skills/qdrant-monitoring";
    home.file.".config/opencode/skills/qdrant-deployment-options".source = "${qdrantSkills}/skills/qdrant-deployment-options";
    home.file.".config/opencode/skills/qdrant-model-migration".source   = "${qdrantSkills}/skills/qdrant-model-migration";
    home.file.".config/opencode/skills/qdrant-version-upgrade".source   = "${qdrantSkills}/skills/qdrant-version-upgrade";

    home.file.".config/opencode/commands/cq-reflect.md".source =
      transformCqCommand "${cqSrc}/plugins/cq/commands/reflect.md";

    home.file.".config/opencode/commands/cq-status.md".source =
      transformCqCommand "${cqSrc}/plugins/cq/commands/status.md";

    # AGENTS.md — global context file; instructs every agent to load the cq skill.
    home.file.".config/opencode/AGENTS.md".text = ''
      <!-- cq:start -->
      ## CQ

      Before starting any implementation task, load the `cq` skill and follow its Core Protocol.
      <!-- cq:end -->
    '';
  }

  agentsModule
]
