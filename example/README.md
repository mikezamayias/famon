# famon Examples

Three shell scripts demonstrating common famon workflows. Each is self-contained and well-commented.

## Scripts

### 1. `live_tail.sh` — Live tail

The simplest flow: connect to a device and stream every Firebase Analytics event in real time. Comments inside cover platform selection, DebugView activation, verbose mode, and raw output.

```bash
./example/live_tail.sh
```

### 2. `json_export.sh` — Export to JSON

Two approaches for getting structured data out of famon:

- **Interactive**: press `s` during monitoring to save a timestamped JSON file.
- **Pipeline**: pipe `--raw --no-color` output through `jq` for ad-hoc JSON conversion.

```bash
./example/json_export.sh
```

### 3. `filtered_session.sh` — Filtered session

Power-user workflow combining `--show-only`, `--hide`, `--stats`, `--suggestions`, and parameter visibility controls. Includes recipes for hiding noisy events, focusing on specific parameters, and separating global parameters.

```bash
./example/filtered_session.sh
```

## Dart example

`famon_example.dart` shows how to invoke famon programmatically from Dart code.

## Quick reference

| Flag | Short | Purpose |
|------|-------|---------|
| `--platform` | `-p` | Target platform (`android`, `ios-simulator`, `ios-device`, `auto`) |
| `--hide` | | Hide named events (repeatable) |
| `--show-only` | `-s` | Only show named events (repeatable) |
| `--show-only-params` | `-P` | Only show named parameters (repeatable) |
| `--global-params` | `-g` | Classify params as global (repeatable) |
| `--hide-global-params` | | Start with global params hidden |
| `--hide-event-params` | | Start with event params hidden |
| `--stats` | | Periodic session statistics |
| `--suggestions` | | Smart suggestions for noisy events |
| `--raw` | `-r` | Raw output without formatting |
| `--verbose` | `-V` | Stream all FA/Crashlytics log lines |
| `--no-color` | | Disable colored output |
| `--enable-debug` | `-D` | Enable DebugView for a package |
| `--raise-log-levels` | | Raise log verbosity |
| `--no-shortcuts` | | Disable keyboard shortcuts |

---

> **Note:** The main project README.md should link to this directory. If it does not yet, please add an "Examples" section pointing to `example/`.
