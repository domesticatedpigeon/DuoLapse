# DuoLapse

Native macOS time-lapse recorder for screen and webcam. `README.md` lists the features; `PLAN.md` holds the architecture, milestones and decisions behind them. Read `PLAN.md` before starting a milestone.

## Layout

- `project.yml`: XcodeGen spec. The `.xcodeproj` is generated and gitignored; never edit or commit it.
- `DuoLapse/`: app target. `App/` holds the entry point and scenes, `Features/<Feature>/` holds SwiftUI views and their models, `Resources/` holds assets.
- `DuoLapseCore/`: Swift package with all logic that can be tested without the UI: capture, sessions, export, system services, naming.
- `.github/workflows/ci.yml`: lint, core tests and app build on a `macos-26` runner.

## Commands

```sh
xcodegen generate                                                   # create DuoLapse.xcodeproj
xcodebuild build -project DuoLapse.xcodeproj -scheme DuoLapse -destination 'platform=macOS'
swift test --package-path DuoLapseCore                              # core unit tests
xcrun swift-format lint --strict --recursive DuoLapse DuoLapseCore  # lint
xcrun swift-format format --in-place --recursive DuoLapse DuoLapseCore
```

On Linux (cloud sessions) there is no Xcode. Use a Swift 6.2 toolchain to run `swift-format` and, while `DuoLapseCore` doesn't import Apple-only frameworks, `swift test`. CI is the source of truth for the app build.

## Conventions

- Swift 6 language mode. The app target defaults to `MainActor` isolation; move work off the main actor explicitly.
- No code comments. Names carry the meaning: types, functions and test names read as sentences.
- Put logic in `DuoLapseCore` and keep views thin. New core code comes with Swift Testing tests.
- Values persisted to disk (`session.json` fields, enum raw values) are a file format. Changing one needs a migration and a test.
- No new third-party dependencies beyond those in `PLAN.md` without asking.
- UI: system controls and materials, SF Symbols, Dynamic Type-friendly text styles, VoiceOver labels on every control, respect Reduce Motion.
- Branches: one PR per milestone into `alpha`. CI must be green before merge.
- Never put links to Claude Code sessions in commit messages, PR descriptions or comments.
