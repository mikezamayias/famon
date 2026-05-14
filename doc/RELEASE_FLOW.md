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

> **Next release must be ≥ 1.4.2.** Both packages are at 1.4.1 on pub.dev — that is the live version. A 1.4.2 attempt was rolled back without ever shipping, so the next bump cannot reuse 1.4.1 and must pick 1.4.2 or later.

### Merge strategy: rebase or squash, never "Create a merge commit"

Repo settings disable "Allow merge commits" — only **Rebase and merge** and **Squash and merge** are available in the GitHub UI. This keeps `dev`'s commit graph linear, easier to review, and easier to bisect.

## Step-by-step

Per the branching protocol, the bump goes through a `chore/release-X.Y.Z` branch off `dev` and lands via a PR back to `dev`. Steps 1–4 happen on that branch; step 5 runs from `dev` after the PR merges.

### 1. Bump every version source atomically

```bash
dart run tool/update_version.dart X.Y.Z
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

### 4. Commit, push the release branch, open the PR

Stage explicitly (no `git add -A`):

```bash
git add pubspec.yaml packages/famon_core/pubspec.yaml lib/src/version.dart \
        CHANGELOG.md packages/famon_core/CHANGELOG.md
git commit -m "chore(release): X.Y.Z"
git push -u origin chore/release-X.Y.Z
gh pr create --base dev --title "chore(release): X.Y.Z" --fill
```

`pr_publish_check.yaml` runs on the PR and re-runs the version cross-check, both `dart pub publish --dry-run`s, and the `famon_core` example smoke run. Wait for it to go green, then merge the PR via the GitHub UI (or `gh pr merge`).

### 5. Merge to `main` and tag

After the PR merges into `dev`, switch to `dev`, pull, then run the helper from a clean working tree:

```bash
git checkout dev
git pull origin dev --ff-only
./tool/release.sh X.Y.Z
```

`tool/release.sh` itself does:

1. Guards: working tree must be clean, both `dev` and `main` must exist locally, local `dev` and `main` must match `origin/dev` and `origin/main`, all six version sources match `X.Y.Z`:
   - root `pubspec.yaml` `version:`
   - root `pubspec.yaml` `famon_core: ^X.Y.Z` constraint
   - `packages/famon_core/pubspec.yaml` `version:`
   - root `CHANGELOG.md` has a `## [X.Y.Z]` heading
   - `packages/famon_core/CHANGELOG.md` has a `## [X.Y.Z]` heading
   - `lib/src/version.dart` has `const packageVersion = 'X.Y.Z';`
2. Fetches `origin/dev`, `origin/main`, and tags, then checks out `dev` to validate and `main` to merge.
3. Runs the merge + tag + push:

   ```bash
   git checkout main
   git merge --no-ff dev
   git tag -a vX.Y.Z -m "Release X.Y.Z"
   git push origin main
   git push origin vX.Y.Z
   ```

The tag push triggers the GitHub Actions workflow `.github/workflows/publish.yaml`.

If you use the **Manual Release** GitHub Actions workflow instead of running `tool/release.sh` locally, the workflow dispatches `publish.yaml` and `github-release.yaml` explicitly after creating the tag. This is required because tags pushed by `GITHUB_TOKEN` do not trigger follow-up `push` workflows.

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
2. Bumping to the next patch (e.g. `1.4.3`) so both packages can be re-cut. Both packages always release together — `famon_core` will be re-published at the new patch even if its source is unchanged. Note this in the `famon_core` CHANGELOG as "version bumped to track CLI release."

### Authentication

Both publish jobs use OIDC trusted publishing (`permissions: id-token: write` plus `dart-lang/setup-dart@v1`, no `PUB_TOKEN` env var). Both packages have GitHub Actions trusted publishing enabled on their pub.dev admin page with:

- Repository: `mikezamayias/famon`
- Tag pattern: `v{{version}}`
- Enabled events: `push` only
- Require GitHub Actions environment: off
- GCP service account: off

**Trusted publishing cannot be configured for a package that does not yet exist on pub.dev.** The very first publish of a new package must be done manually (see [Manual publish](#manual-publish) below); after the package appears on pub.dev, return to its admin page and enable Automated publishing.

## Continuous integration on PRs

`.github/workflows/pr_publish_check.yaml` runs on every PR (and push to `dev`/`main`) that touches publish-relevant files (`pubspec.yaml`, `lib/src/version.dart`, `packages/famon_core/**`, `.pubignore`, `tool/update_version.dart`, `tool/release.sh`, the publish workflows). It runs four jobs:

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
