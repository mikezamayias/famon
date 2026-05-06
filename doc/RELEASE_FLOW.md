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

A `dependency_overrides` hint is expected on the root `famon` package — it carries the local `path: packages/famon_core` override, which pub strips from the published pubspec but warns about during dry-run.

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

The tag push triggers the GitHub Actions workflow `.github/workflows/publish.yaml`.

## Automated publish workflow

Tag pushes trigger two independent workflows in parallel:

- `.github/workflows/publish.yaml` — publishes both packages to pub.dev (this section).
- `.github/workflows/github-release.yaml` — creates a GitHub Release with the changelog body.

`publish.yaml` runs three jobs in sequence:

1. **`verify-versions`** — fails fast if the tag, root `pubspec.yaml`, `packages/famon_core/pubspec.yaml`, and `lib/src/version.dart` disagree, or if any source is empty.
2. **`publish-core`** — `dart pub publish --dry-run` then `--force` for `famon_core`.
3. **`publish-cli`** — polls `https://pub.dev/api/packages/famon_core` until the new version appears (up to 5 minutes), then publishes the root `famon` package.

The CLI cannot publish before the library because the published `famon` pubspec resolves `famon_core: ^X.Y.Z` from pub.dev (the local `dependency_overrides` is stripped on publish).

### Recovery from a partial publish

Pub.dev does not allow re-publishing the same version. If `publish-core` succeeds but `publish-cli` fails, `famon_core@X.Y.Z` is on pub.dev permanently and the CLI half is still missing. Recover by:

1. Investigating the `publish-cli` failure (typically transient pub.dev 5xx or indexing latency).
2. Bumping to the next patch (e.g. `1.4.2`) so both packages can be re-cut. Both packages always release together — `famon_core` will be re-published at the new patch even if its source is unchanged. Note this in the `famon_core` CHANGELOG as "version bumped to track CLI release."

### Authentication

Both publish jobs use OIDC trusted publishing (`permissions: id-token: write` plus `dart-lang/setup-dart@v1`). For this to work, each package must be configured for "Automated publishing from GitHub Actions" in its pub.dev admin page, with the repository, workflow, and tag pattern matching this workflow. **`famon_core` cannot be configured for trusted publishing until after its first manual publish** (pub.dev requires the package to exist).

## Continuous integration on PRs

`.github/workflows/pr_publish_check.yaml` runs on every PR that touches publish-relevant files (`pubspec.yaml`, `lib/src/version.dart`, `packages/famon_core/**`, `.pubignore`, `tool/update_version.dart`, `tool/release.sh`, the publish workflows). It runs four jobs:

- `verify-versions-consistent` — same cross-check as the tag-time job, minus the tag comparison.
- `dry-run-famon-core` and `dry-run-famon` — `dart pub publish --dry-run` for both packages, catching publish-blocking issues before tagging.
- `example-smoke-run` — executes `packages/famon_core/example/famon_core_example.dart` to keep the published example honest.

## Manual publish

Required for the very first publish of either package (pub.dev cannot configure trusted publishing for a package that does not yet exist), and useful as a recovery path if the workflow is unavailable:

```bash
dart pub login
(cd packages/famon_core && dart pub publish)
sleep 60
dart pub publish
```

## Dependabot

Dependabot pull requests target `dev`. Group or defer dependency updates as needed. Keep release-specific changes (version bump and changelogs) in a dedicated `chore(release)` commit.
