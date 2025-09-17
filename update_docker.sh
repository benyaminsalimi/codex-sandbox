#!/usr/bin/env bash

set -e

platforms="linux/amd64,linux/arm64"

# Check if npm is available
if ! command -v npm &> /dev/null; then
    echo "Error: npm is not installed or not in PATH"
    exit 1
fi

echo "Getting latest version from npm registry for @openai/codex"
codex_version=$(npm view @openai/codex version)

if [ -z "$codex_version" ]; then
    echo "Error: Could not retrieve version from npm registry"
    exit 1
fi

image_name=benyamin/codex-sandbox:"${codex_version}"

if [ -z "$(DOCKER_CLI_EXPERIMENTAL=enabled docker manifest inspect "$image_name" 2> /dev/null)" ]; then
  echo "Building for codex version: ${codex_version}"

  docker run --privileged --rm tonistiigi/binfmt --install all
  docker buildx create --use --name builder
  docker buildx inspect --bootstrap builder

  docker buildx build \
    --platform "$platforms" \
    --build-arg "CODEX_VERSION=${codex_version}" \
    -t "$image_name" \
    -t "benyamin/codex-sandbox:latest" \
    --push .

  # Extract current version from VERSION.md
  current_version=$(grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' VERSION.md 2>/dev/null || echo "unknown")
  
  echo "needs_version_update=true" >> $GITHUB_OUTPUT
  echo "latest_version=${codex_version}" >> $GITHUB_OUTPUT
  echo "current_version=${current_version}" >> $GITHUB_OUTPUT

  echo "Updating VERSION.md from ${current_version} to ${codex_version}"
  echo "${codex_version}" > VERSION.md
  echo "VERSION.md updated successfully"

  echo "Done!"
else
  echo "Latest codex image version already exists, version: ${codex_version}"
  echo "needs_version_update=false" >> $GITHUB_OUTPUT
fi