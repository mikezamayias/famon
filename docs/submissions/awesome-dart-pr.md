# awesome-dart PR Draft

> Target repo: https://github.com/yissachar/awesome-dart
> File to edit: `README.md`
> Category: **Tools**

---

## PR Title

Add famon — Real-time Firebase Analytics event monitor CLI

## Entry to Add

Add to the bottom of the **Tools** section in `README.md`:

```markdown
* [famon](https://github.com/mikezamayias/famon) - Real-time CLI monitor for Firebase Analytics events across Android and iOS, with regex-based log parsing and event filtering.
```

## PR Description

```
### What is famon?

famon is a Dart CLI tool that monitors Firebase Analytics events in real-time by parsing platform log output (Android logcat, iOS Simulator via xcrun simctl, and iOS devices via idevicesyslog).

### Why it fits in awesome-dart

- **Pure Dart CLI** — no Flutter dependency, built entirely with Dart
- **Actively maintained** — v1.3.0, MIT licensed
- **Well documented** — full README with install instructions, usage examples, and troubleshooting
- **Useful function** — fills a gap in Firebase Analytics debugging tooling; no equivalent CLI exists
- **Works with latest SDK** — Dart 3.x compatible

### Key features

- Cross-platform log parsing (Android, iOS Simulator, iOS device)
- Event filtering with --hide and --show-only flags
- Colorized, formatted output with full parameter and items array parsing
- Session statistics and smart filter suggestions
- Regex factory pattern with early-exit markers for performant stream processing

### Checklist

- [x] Actively maintained
- [x] Performs a useful function
- [x] Well documented
- [x] Works with the latest SDK
- [x] Individual PR for a single suggestion
- [x] Format: `[package](link) - Description.`
- [x] Description starts with capital, ends with full stop
- [x] Does not mention "Dart" in description
- [x] Spelling and grammar checked
```

## Notes

- awesome-dart uses `* [name](link) - Description.` format (asterisk, not dash).
- The Tools section is the best fit — famon is a developer tool, not a library/framework.
- Existing Tools entries include DevTools, Stagehand, Dart Code Metrics, m2cgen, and Lakos.
