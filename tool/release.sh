#!/usr/bin/env bash
#
# Release helper. PR-based: opens (or reuses) a `dev → main` pull
# request, waits for the required CI checks to pass, merges the PR
# with the "merge" method so dev's commits become ancestors of main,
# then tags the resulting merge commit on main. The tag push triggers
# .github/workflows/publish.yaml, which publishes both packages to
# pub.dev.
#
# Why a PR and not a direct push?
#
# The "Protect main" repository ruleset requires a pull request, with
# the same six required status checks every regular contribution must
# pass. Direct pushes are rejected for everyone, including admins —
# the release flow earns its merge the same way every other change
# does. Trusted-publishing OIDC still authenticates the publish jobs
# triggered by the tag push.
#
# Prerequisites:
# - `gh` CLI is installed and authenticated for this repository.
# - The release-prep PR (`chore(release): X.Y.Z`) has already merged
#   into `dev` so the version sources and changelogs sit at the tip
#   of `dev`.

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

git fetch origin \
  +refs/heads/dev:refs/remotes/origin/dev \
  +refs/heads/main:refs/remotes/origin/main \
  --tags
git branch --track dev origin/dev 2>/dev/null || true
git branch --track main origin/main 2>/dev/null || true

if ! git show-ref --verify --quiet refs/heads/dev; then
  echo "Branch 'dev' not found. Ensure it exists locally." >&2
  exit 1
fi

if ! git show-ref --verify --quiet refs/heads/main; then
  echo "Branch 'main' not found. Ensure it exists locally." >&2
  exit 1
fi

git checkout dev
git pull --ff-only origin dev
if [[ "$(git rev-parse dev)" != "$(git rev-parse origin/dev)" ]]; then
  echo "Local 'dev' is not exactly at origin/dev. Reconcile/push dev before releasing." >&2
  exit 1
fi

if ! grep -qF "version: $VERSION" pubspec.yaml; then
  echo "pubspec.yaml version is not set to $VERSION" >&2
  exit 1
fi

if ! grep -qF "famon_core: ^$VERSION" pubspec.yaml; then
  echo "pubspec.yaml famon_core constraint is not ^$VERSION" >&2
  echo "Run: dart run tool/update_version.dart $VERSION" >&2
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

# Re-use an existing open release PR if one is already there.
PR_NUMBER="$(gh pr list \
  --base main --head dev \
  --state open --json number --jq '.[0].number // empty')"

if [[ -z "$PR_NUMBER" ]]; then
  PR_URL="$(gh pr create \
    --base main --head dev \
    --title "chore(release): $VERSION → main" \
    --body $'Automated release-sync PR opened by `tool/release.sh '"$VERSION"$'`.\n\nMerges `dev` into `main` so the next `v'"$VERSION"$'` tag points at the resulting merge commit. The tag push triggers `.github/workflows/publish.yaml`, which publishes both packages to pub.dev via OIDC trusted publishing.\n\nUse **Create a merge commit** when merging this PR — `tool/release.sh` requests it explicitly. Squash would lose dev\'s commit ancestry on main and reintroduce the divergence this PR-based flow is designed to fix.')"
  PR_NUMBER="${PR_URL##*/}"
fi

echo "Release PR: #$PR_NUMBER"
echo "Waiting for required CI checks…"

gh pr checks "$PR_NUMBER" --watch --required

STATE="$(gh pr view "$PR_NUMBER" \
  --json mergeStateStatus,mergeable \
  --jq '"\(.mergeStateStatus)/\(.mergeable)"')"
if [[ "$STATE" != "CLEAN/MERGEABLE" ]]; then
  echo "PR #$PR_NUMBER is not mergeable: $STATE" >&2
  echo "Resolve threads or conflicts on the PR, then re-run this script." >&2
  exit 1
fi

gh pr merge "$PR_NUMBER" --merge

git checkout main
git pull --ff-only origin main

if ! grep -qF "version: $VERSION" pubspec.yaml; then
  echo "After merge, pubspec.yaml on main does not say version $VERSION." >&2
  echo "Inspect the merged result and re-run with a fresh tag if needed." >&2
  exit 1
fi

git tag -a "v$VERSION" -m "Release $VERSION"
git push origin "v$VERSION"

echo
echo "Tagged v$VERSION at $(git rev-parse main)."
echo "Tag pushed. .github/workflows/publish.yaml will publish both packages."
