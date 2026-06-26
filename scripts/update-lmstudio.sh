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

# Replace the version and sha256 in the lmstudio override
sed -i '' "s/version = \"[^\"]*\";/version = \"${version}\";/" "$FILE"
sed -i '' "s/sha256 = \"[^\"]*\";/sha256 = \"${hash}\";/" "$FILE"

echo "Updated flake.nix with version ${version}"
