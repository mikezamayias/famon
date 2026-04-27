# awesome-flutter PR Draft

> Target repo: https://github.com/Solido/awesome-flutter
> File to edit: `source.md` (NOT `README.md`)
> Category: **Analytics** (under Components > Analytics)

---

## PR Title

Add famon — Real-time Firebase Analytics event monitor CLI

## Entry to Add

Add to the bottom of the **Analytics** section in `source.md`:

```markdown
- [famon](https://github.com/mikezamayias/famon) <!--stargazers:mikezamayias/famon--> - Real-time Firebase Analytics event monitor CLI with regex factory and early-exit parsing by [Mike Zamayias](https://github.com/mikezamayias)
```

## PR Description

```
### Why this belongs in awesome-flutter

**famon** is a Dart CLI tool that streams Firebase Analytics events in real-time from Android (logcat), iOS Simulator (xcrun simctl), and physical iOS devices (idevicesyslog). It fills a gap in the Flutter analytics tooling ecosystem — there is no other dedicated CLI for live-monitoring Firebase Analytics events across all three platforms.

### What it does

- Streams Firebase Analytics events as they fire, parsed and colorized
- Cross-platform: Android, iOS Simulator, iOS device
- Event filtering: `--hide` and `--show-only` flags for noise reduction
- Session statistics and smart filter suggestions
- Full parameter and items array parsing
- Regex factory with early-exit markers for efficient log line processing

### Checklist

- [x] Tested and documented (README with install, usage, troubleshooting)
- [x] MIT licensed
- [x] Actively maintained (v1.3.0)
- [x] Individual PR for a single suggestion
- [x] Entry added to bottom of relevant category (Analytics)
- [x] Format: `[resource](link) - Description by [Author](link)`
- [x] Title-cased where applicable
- [x] Description does not mention "Flutter" (implied)
- [x] Trailing whitespace removed
```

## Notes

- awesome-flutter requires 35 stars minimum. Ensure the repo meets this threshold before submitting.
- Submit changes to `source.md`, not `README.md` (per contribution guidelines).
- The Analytics category currently has 3 entries (Usage, Firebase Analytics, Pure Mixpanel), so famon fits naturally as a complementary debugging/monitoring tool.
