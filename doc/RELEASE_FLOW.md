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

## Step-by-step

Run from the `dev` branch (or a `chore/release-X.Y.Z` branch off `dev` that you PR back to `dev` first).

### 1. Bump every version source atomically

```bash
dart run tool/update_version.dart 1.4.1
```

`tool/update_version.dart` rewrites four sources in a preflight + apply pipeline so a partial failure leaves the repo untouched:

- `pubspec.yaml` — `version:`
- `pubspec.yaml` — `famon_core: ^X.Y.Z` constraint (kept in lockstep with the library so major bumps stay coherent)
- `packages/famon_core/pubspec.yaml` — `version:`
- `lib/src/version.dart` — `packageVersion` constant

### 2. Update both changelogs

Both packages keep their own changelog (Keep a Changelog format):

- `CHANGELOG.md` — root, end-user-facing CLI changes.
- `packages/famon_core/CHANGELOG.md` — library API changes.

Add a new `## [X.Y.Z] - YYYY-MM-DD` section to each. If a release only touches the CLI, the `famon_core` entry can simply note "no functional changes — version bumped to track CLI release."

### 3. Run pre-push checks

Per the project's branching protocol, every push runs format, analyzer (with `--fatal-warnings`), and the full test suite locally first. For a release commit, also dry-run both packages:

```bash
dart format --set-exit-if-changed .
dart analyze --fatal-warnings
dart test
(cd packages/famon_core && dart pub publish --dry-run)
dart pub publish --dry-run
```

The dry-runs should report zero warnings. A `dependency_overrides` hint is expected on the root `famon` package — it carries the local `path: packages/famon_core` override, which pub strips from the published pubspec but warns about during dry-run.

### 4. Commit and push `dev`

Stage explicitly (no `git add -A`) and push:

```bash
git add pubspec.yaml packages/famon_core/pubspec.yaml lib/src/version.dart \
        CHANGELOG.md packages/famon_core/CHANGELOG.md
git commit -m "chore(release): 1.4.1"
git push origin dev
```

`pr_publish_check.yaml` runs on the resulting CI build and re-runs both dry-runs and the version cross-check — wait for it to go green before tagging.

### 5. Merge to `main` and tag

Use the helper:

```bash
./tool/release.sh 1.4.1
```

It guards against:

- Dirty working tree
- Missing `dev` or `main` branch locally
- Any of the five version sources (two pubspec `version:` fields, both `## [X.Y.Z]` changelog headings, and `packageVersion`) not matching the requested version

…then runs the merge + tag + push:

```bash
git checkout main
git merge --no-ff dev
git tag -a v1.4.1 -m "Release 1.4.1"
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

Both publish jobs use OIDC trusted publishing (`permissions: id-token: write` plus `dart-lang/setup-dart@v1`, no `PUB_TOKEN` env var). Both packages have GitHub Actions trusted publishing enabled on their pub.dev admin page with:

- Repository: `mikezamayias/famon`
- Tag pattern: `v{{version}}`
- Enabled events: `push` only
- Require GitHub Actions environment: off
- GCP service account: off

**Trusted publishing cannot be configured for a package that does not yet exist on pub.dev.** The very first publish of a new package must be done manually (see [Manual publish](#manual-publish) below); after the package appears on pub.dev, return to its admin page and enable Automated publishing.

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
