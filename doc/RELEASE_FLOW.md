# Release Flow

`famon` is a monorepo that publishes two packages to pub.dev:

| Package | Path | Role |
|---|---|---|
| [`famon_core`](https://pub.dev/packages/famon_core) | `packages/famon_core/` | Reusable library (parsing, formatting, persistence) |
| [`famon`](https://pub.dev/packages/famon) | `.` (repo root) | CLI frontend, depends on `famon_core` |

Both packages share a single version. They are released together.

## Branches

- `dev` is the default branch for day-to-day work and pull requests.
- `main` tracks code that has been released to pub.dev.

All feature and fix branches branch from `dev` (e.g. `feature/<name>`, `fix/<name>`) and merge back via pull requests targeting `dev`.

## Bump version

Use the helper script — it updates all three sources of truth atomically:

```bash
dart run tool/update_version.dart 1.4.1
```

This rewrites:

- `pubspec.yaml`
- `packages/famon_core/pubspec.yaml`
- `lib/src/version.dart` (`packageVersion` constant)

## Update changelogs

Both packages keep their own changelog (Keep a Changelog format):

- `CHANGELOG.md` — root, end-user-facing CLI changes.
- `packages/famon_core/CHANGELOG.md` — library API changes.

Add a new `## [X.Y.Z] - YYYY-MM-DD` section to each. If a release only touches the CLI, the `famon_core` entry can simply note "no functional changes — version bumped to track CLI release."

## Commit

Stage explicitly and commit:

```bash
git add pubspec.yaml packages/famon_core/pubspec.yaml lib/src/version.dart \
        CHANGELOG.md packages/famon_core/CHANGELOG.md
git commit -m "chore(release): 1.4.1"
```

## Pre-tag verification

Before tagging, both packages must dry-run cleanly. Uncommitted-file warnings disappear once the release commit is in place.

```bash
dart format --set-exit-if-changed .
dart analyze --fatal-warnings
dart test
(cd packages/famon_core && dart pub publish --dry-run)
dart pub publish --dry-run
```

A `dependency_overrides` hint is expected on the root `famon` package — it carries the local `path: packages/famon_core` override, which pub ignores at publish time but mentions in the dry-run.

## Tag and push

After preparing the release on `dev`:

1. Merge `dev` into `main`:

   ```bash
   git checkout main
   git merge --no-ff dev
   ```

2. Create an annotated tag matching the version in `pubspec.yaml`:

   ```bash
   git tag -a v1.4.1 -m "Release 1.4.1"
   ```

3. Push when ready to publish:

   ```bash
   git push origin main
   git push origin v1.4.1
   ```

The tag push triggers `.github/workflows/publish.yaml`.

## Automated publish workflow

`.github/workflows/publish.yaml` runs three jobs in sequence on tag push:

1. **`verify-versions`** — fails fast if the tag, root `pubspec.yaml`, `packages/famon_core/pubspec.yaml`, and `lib/src/version.dart` disagree.
2. **`publish-core`** — `dart pub publish --dry-run` then `--force` for `famon_core`.
3. **`publish-cli`** — waits 60 seconds for pub.dev to index `famon_core`, then publishes the root `famon` package.

The CLI cannot publish before the library because the published `famon` pubspec resolves `famon_core: ^X.Y.Z` from pub.dev (the local `dependency_overrides` is stripped on publish).

If a job fails, fix the issue, bump to the next patch (e.g. `1.4.2`), retag, and push. Pub.dev does not allow re-publishing the same version.

## Manual publish (one-time recovery)

If a tag was pushed without a publish workflow (as happened pre-1.4.0) or the workflow is broken:

```bash
dart pub login
(cd packages/famon_core && dart pub publish)
sleep 60
dart pub publish
```

## Dependabot

Dependabot pull requests target `dev`. Group or defer dependency updates as needed. Keep release-specific changes (version bump and changelogs) in a dedicated `chore(release)` commit.
