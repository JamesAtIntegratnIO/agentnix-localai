#!/usr/bin/env bash
set -euo pipefail

# Fetch latest version URL
url=$(curl -ILs -o /dev/null -w '%{url_effective}' "https://lmstudio.ai/download/latest/darwin/arm64")
version="$(echo "${url}" | cut -d/ -f6)"

# Compute hash
hash=$(nix --extra-experimental-features nix-command hash convert --hash-algo sha256 "$(nix-prefetch-url "${url}")")

echo "Latest version: ${version}"
echo "New hash: ${hash}"

# Update flake.nix
FILE="/Users/jdreier/Projects/nix-home/flake.nix"

# Replace the version and sha256 in the lmstudio override block only
# Using perl -0pe for multi-line aware substitution scoped to the lmstudio override
# ${1}/${2} disambiguates from the version number (avoids $10 being read as capture group 10)
perl -i -0pe 's/(lmstudio = super\.lmstudio\.overrideAttrs \(old: let\s*\n[ \t]*version = ")[^"]*(")/${1}'"${version}"'${2}/s' "$FILE"
perl -i -0pe 's/(lmstudio = super\.lmstudio\.overrideAttrs \(old: let\s*\n\s*in \{\s*\n\s*inherit version;\s*\n\s*src = super\.fetchurl \{\s*\n\s*url = "[^"]*";\n[ \t]*sha256 = ")[^"]*(")/${1}'"${hash}"'${2}/s' "$FILE"

echo "Updated flake.nix with version ${version}"
