# r/FlutterDev Showcase Post Draft

> Subreddit: https://reddit.com/r/FlutterDev
> Flair: Tooling / Show & Tell (check current available flairs)

---

## Title Options

1. `I built a CLI that streams Firebase Analytics events in real-time from logcat — famon v1.3.0`
2. `famon: real-time Firebase Analytics monitor for Android + iOS (Dart CLI)`
3. `Tired of sifting through logcat for Firebase events? I made a CLI for that`

**Recommended:** Option 1

---

## Post Body

Hey r/FlutterDev,

I built **famon** — a Dart CLI tool that monitors Firebase Analytics events in real-time. If you have ever found yourself running `adb logcat | grep FA` and squinting at raw Bundle output trying to figure out whether your events are actually firing with the right parameters, this is for you.

### What it does

famon connects to your device's log stream and parses Firebase Analytics events as they happen:

- **Android** via `adb logcat`
- **iOS Simulator** via `xcrun simctl`
- **iOS Device** via `idevicesyslog`

It outputs clean, colorized events with all parameters and item arrays fully parsed. You can filter noise with `--hide screen_view --hide _vs` or focus on specific events with `--show-only my_event`. It also tracks session statistics and suggests filters based on event frequency.

### The interesting technical bit

The core parsing uses a **regex factory pattern with early-exit markers**. Every logcat line goes through the parser, so performance matters. Instead of running every regex against every line, the parser checks for cheap string markers first (like `"Logging event"` or `"FA-SVC"`) and only compiles/runs the full regex if the marker matches. All regex patterns are `static final` — never compiled inside hot loops.

Both the Android and iOS parsers produce identical `AnalyticsEvent` objects, so the formatter and statistics layer are completely platform-agnostic.

### How to install

famon is a Dart CLI, not a pub package (it is a standalone tool, not a library):

```bash
dart pub global activate famon
```

Or from source:

```bash
git clone https://github.com/mikezamayias/famon.git
cd famon
dart pub get
dart compile exe bin/famon.dart -o famon
```

### Quick usage

```bash
famon monitor                                    # auto-detect platform
famon monitor --platform android
famon monitor --hide screen_view --hide _vs      # filter noise
famon monitor --show-only purchase_event          # focus mode
famon monitor --stats --suggestions              # session analytics
```

### Links

- GitHub: https://github.com/mikezamayias/famon
- MIT licensed, v1.3.0

I would genuinely appreciate feedback — especially on the parsing approach, the CLI UX, or features you would want. If you work with Firebase Analytics regularly, I would like to know how this fits (or does not fit) into your workflow.

---

## Posting Notes

- Post on a weekday (Tue-Thu) for best visibility on r/FlutterDev.
- Use the appropriate flair (Tooling, Show & Tell, or Package/Plugin depending on what is available).
- Respond to comments promptly in the first few hours.
- If someone asks about pub.dev: explain it is a CLI tool installed via `dart pub global activate`, not a library dependency.
- Cross-post to r/dartlang if reception is good.
