## ADDED Requirements

### Requirement: Common permission includes lsp
The `commonPermission` attribute set SHALL include `lsp = "allow"` as a permission entry.

#### Scenario: commonPermission has lsp allow
- **WHEN** common.nix is evaluated
- **THEN** `commonPermission.lsp` equals `"allow"`

### Requirement: Subagent permission includes lsp
The `mkSubagentPermission` function SHALL include `lsp = "allow"` in the returned permission set.

#### Scenario: mkSubagentPermission returns lsp allow
- **WHEN** mkSubagentPermission is called with any bash config
- **THEN** the returned permission set includes `lsp = "allow"`
