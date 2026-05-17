# LLM changelog tool design

**Goal:** Add maintainer-only tooling that drafts and validates release changelog entries for both published packages without exposing anything through the `famon` CLI.

**Status:** Implemented.

## Context

`famon` publishes two packages from one repository:

- `famon` from the repo root.
- `famon_core` from `packages/famon_core/`.

Both packages release together. Today, `tool/release.sh` refuses to tag unless both changelogs already contain the target version. That is the right safety model, but drafting two clean changelog sections from git history is boring, easy to forget, and easy to fill with commit noise.

The new tool should use an LLM only for prose. File edits, validation, version checks, and release gates stay deterministic.

## Non-Goals

- Do not expose this as `famon changelog` or any other user-facing CLI command.
- Do not let an LLM tag, publish, merge, or push releases.
- Do not replace human review of changelog entries in the release-prep PR.
- Do not add CI secrets or hosted LLM API requirements.

## Tool Shape

Create one repo-local Dart tool:

```bash
dart run tool/changelog.dart prompt X.Y.Z
dart run tool/changelog.dart draft X.Y.Z --llm codex --yes
dart run tool/changelog.dart validate X.Y.Z
```

The file lives under `tool/`, like `tool/update_version.dart`. It is for maintainers working from a clone of the repository, not for users who install `famon` from pub.dev.

## Commands

### `draft`

Drafts entries for both changelogs.

Responsibilities:

- Determine the previous release tag, for example `v1.4.1`.
- Collect git commits from `vPREVIOUS..HEAD`.
- Use `gh` PR metadata when available, but do not require it.
- Detect whether changes touched `packages/famon_core/`.
- Build a strict prompt for public release notes.
- Call a local LLM CLI only when `--yes` is present. Supported `--llm` values:
  - `codex`
  - `claude`
- Insert the generated sections near the top of:
  - `CHANGELOG.md`
  - `packages/famon_core/CHANGELOG.md`

The generated text should be short and public-facing. It should not mention internal branch names, Codacy, CodeRabbit, release-please cleanup, private plans, or generic CI plumbing unless that detail matters to someone reading the public changelog.

### `prompt`

Writes the same prompt/context that `draft` would send to an LLM, without calling an LLM.

Example output path:

```text
.local/changelog/draft-X.Y.Z-prompt.md
```

This is the fallback when local LLM CLIs are unavailable or when the maintainer wants to inspect the prompt first.

Maintainers and LLM agents should use `prompt` before `draft`. The prompt file is
the reviewable boundary for cost and prompt-injection safety.

### `validate`

Validates changelog readiness without calling an LLM.

Checks:

- `CHANGELOG.md` contains a `## [X.Y.Z]` section.
- `packages/famon_core/CHANGELOG.md` contains a `## [X.Y.Z]` section.
- Both sections contain a valid release date.
- Both sections contain a compare link from the previous tag to `vX.Y.Z`.
- Sections are not empty.
- Sections do not contain placeholders such as `TBD`, `TODO`, or `lorem`.
- Public changelog text avoids known internal-noise terms unless explicitly allowed.
- If `packages/famon_core/` changed since the previous tag, the core changelog must not claim there were no functional changes.
- If `packages/famon_core/` did not change, the core changelog may use a short lockstep-version note.

## Release Flow

The release-prep flow becomes:

```bash
dart run tool/update_version.dart X.Y.Z
dart run tool/changelog.dart prompt X.Y.Z
dart run tool/changelog.dart draft X.Y.Z --llm codex --yes
dart run tool/changelog.dart validate X.Y.Z
```

Then open the normal release-prep PR into `dev`. Review the generated changelog like any other public release text.

After the release-prep PR merges, release continues separately:

```bash
./tool/release.sh X.Y.Z
```

The changelog tool does not create release PRs or tags.

## Documentation updates

Keep documentation small:

- Add a short mention in `doc/RELEASE_FLOW.md` under the changelog step.
- Keep detailed behavior in this design doc and the tool help text.
- Do not add a long public-facing README section.

## Safety model

- LLM output is a draft.
- LLM execution requires the explicit `--yes` flag; the safe default is to write
  and review the prompt without calling an LLM.
- The prompt has a fixed character budget to limit accidental usage and runaway
  release context.
- Commit subjects and PR titles are fenced as untrusted data. They must never be
  concatenated into the instruction section or treated as prompt instructions.
- Providers that require broad tool permissions for this prose-only task are not
  supported by the helper.
- Codex must run with `--sandbox read-only`, `--ignore-user-config`,
  `--ignore-rules`, and `--ephemeral` so local agent configuration cannot
  widen the changelog helper's permissions.
- Claude must run with an empty `--allowedTools` list so the helper is a
  prose-only generation call.
- Deterministic validation is required before release.
- The release-prep PR remains the human review gate.
- The generated changelog is committed before tagging.
- `tool/release.sh` or its future replacement still refuses to tag if either changelog lacks the target version.
