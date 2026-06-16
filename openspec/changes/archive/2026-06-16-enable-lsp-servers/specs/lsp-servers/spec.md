## ADDED Requirements

### Requirement: LSP servers are installed as Nix packages
The system SHALL include LSP server binaries for Python (pyright) and JavaScript/TypeScript (typescript-language-server) in the user package set.

#### Scenario: pyright is available in user packages
- **WHEN** home-manager applies the user package set
- **THEN** `pyright` is available on the user's PATH

#### Scenario: typescript-language-server is available in user packages
- **WHEN** home-manager applies the user package set
- **THEN** `typescript-language-server` is available on the user's PATH

#### Scenario: nixd is available as a system package
- **WHEN** nix-darwin activates the system package set
- **THEN** `nixd` is available on the system PATH
