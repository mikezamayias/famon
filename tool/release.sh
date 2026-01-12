#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-}"

if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <version>" >&2
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree not clean. Commit or stash changes before releasing." >&2
  exit 1
fi

if ! git show-ref --verify --quiet refs/heads/development; then
  echo "Branch 'development' not found. Ensure it exists locally." >&2
  exit 1
fi

if ! git show-ref --verify --quiet refs/heads/main; then
  echo "Branch 'main' not found. Ensure it exists locally." >&2
  exit 1
fi

git checkout development

if ! grep -q "version: $VERSION" pubspec.yaml; then
  echo "pubspec.yaml version is not set to $VERSION" >&2
  exit 1
fi

if ! grep -q "## \\[$VERSION\\]" CHANGELOG.md; then
  echo "CHANGELOG.md does not contain a section for $VERSION" >&2
  exit 1
fi

git checkout main
git merge --no-ff development

git tag -a "v$VERSION" -m "Release $VERSION"

git push origin main
git push origin "v$VERSION"

