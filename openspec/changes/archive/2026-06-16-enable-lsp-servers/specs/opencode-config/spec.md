## ADDED Requirements

### Requirement: Opencode config supports lsp key
The `mkOpencodeEnv` function SHALL accept an `lsp` parameter that is merged into the generated opencode.json under the `lsp` key.

#### Scenario: lsp parameter is merged into config
- **WHEN** mkOpencodeEnv is called with `lsp = true`
- **THEN** the generated opencode.json contains `"lsp": true`

#### Scenario: lsp parameter is optional
- **WHEN** mkOpencodeEnv is called without an lsp parameter
- **THEN** the generated opencode.json does not contain an lsp key
