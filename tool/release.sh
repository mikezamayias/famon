#!/usr/bin/env bash
#
# Manual release helper — kept as the bypass path for when release-please
# (.github/workflows/release-please.yaml) cannot be used: an emergency
# patch, a release-please outage, or a hand-curated release whose CHANGELOG
# you want to author yourself. For routine releases, prefer release-please.
#
# Running both flows for the same version creates duplicate tags and
# fights over CHANGELOG content — only use one path per release.

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

if ! git show-ref --verify --quiet refs/heads/dev; then
  echo "Branch 'dev' not found. Ensure it exists locally." >&2
  exit 1
fi

if ! git show-ref --verify --quiet refs/heads/main; then
  echo "Branch 'main' not found. Ensure it exists locally." >&2
  exit 1
fi

git checkout dev

if ! grep -qF "version: $VERSION" pubspec.yaml; then
  echo "pubspec.yaml version is not set to $VERSION" >&2
  exit 1
fi

if ! grep -qF "version: $VERSION" packages/famon_core/pubspec.yaml; then
  echo "packages/famon_core/pubspec.yaml version is not set to $VERSION" >&2
  echo "Run: dart run tool/update_version.dart $VERSION" >&2
  exit 1
fi

if ! grep -qF "## [$VERSION]" CHANGELOG.md; then
  echo "CHANGELOG.md does not contain a section for $VERSION" >&2
  exit 1
fi

if ! grep -qF "## [$VERSION]" packages/famon_core/CHANGELOG.md; then
  echo "packages/famon_core/CHANGELOG.md does not contain a section for $VERSION" >&2
  exit 1
fi

if ! grep -qF "const packageVersion = '$VERSION';" lib/src/version.dart; then
  echo "lib/src/version.dart does not contain version $VERSION" >&2
  echo "Expected: const packageVersion = '$VERSION';" >&2
  echo "Run: dart run tool/update_version.dart $VERSION" >&2
  exit 1
fi

git checkout main
git merge --no-ff dev

git tag -a "v$VERSION" -m "Release $VERSION"

git push origin main
git push origin "v$VERSION"

