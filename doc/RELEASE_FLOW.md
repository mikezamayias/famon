# Release Flow

## Branches

- `dev` is the default branch for day-to-day work and pull requests.
- `main` tracks code that has been released to pub.dev.

All feature and fix branches branch from `dev` and merge back via pull requests.

## Versioning and changelog

1. Update `pubspec.yaml` with the new `version`.
2. Update `CHANGELOG.md` with a new section for that version.
3. Commit:

   ```bash
   git commit -am "chore(release): 1.0.2"
   ```

## Tagging releases

After preparing a release on `dev`:

1. Merge `dev` into `main`:

   ```bash
   git checkout main
   git merge --no-ff dev
   ```

2. Create an annotated tag matching the version in `pubspec.yaml`:

   ```bash
   git tag -a v1.0.2 -m "Release 1.0.2"
   ```

3. Push when ready to publish:

   ```bash
   git push origin main
   git push origin v1.0.2
   ```

## Dependabot

Dependabot pull requests target `dev`. Group or defer dependency updates as needed. Keep release-specific changes (version bump and changelog) in a dedicated `chore(release)` commit.
