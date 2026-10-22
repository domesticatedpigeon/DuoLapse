# DuoLapse Implementation Plan

Native macOS time-lapse recorder for screen and webcam, built from the feature list in `README.md`.

## 1. Decisions

| Area | Choice | Why |
| --- | --- | --- |
| Minimum OS | macOS 26 Tahoe | Liquid Glass icon and materials are a stated feature; avoids `#available` branches everywhere. |
| Language | Swift 6, strict concurrency | Capture, timers and file I/O cross actors; let the compiler catch races. |
| UI | SwiftUI (`Window`, `MenuBarExtra`, `Settings`), AppKit only where SwiftUI has gaps | Native look, small codebase. |
| State | `@Observable` models, one `RecordingController` actor owning the active session | Enforces “one active recording” in a single place. |
| Screen capture | `SCScreenshotManager.captureImage` per tick | Grabs a single frame on demand. No running stream, so near-zero idle cost. |
| Webcam capture | `AVCaptureSession` + `AVCaptureVideoDataOutput`, keep latest frame only | See §4.2 for the start/stop trade-off. |
| Frame storage | HEIC files on disk, one per tick, per source | Crash-safe by construction, and enables re-export at any duration. |
| Export | `AVAssetWriter`, HEVC (H.264 fallback), 30 fps, Core Image compositing | Hardware-encoded, no third-party dependencies. |
| Hotkeys | `KeyboardShortcuts` (sindresorhus) | Proven recorder UI plus global registration. The only third-party runtime dependency. |
| Login item | `SMAppService.mainApp` | Current API; no helper app needed. |
| Updates | Sparkle 2 | Required for out-of-store distribution. |
| Distribution | Developer ID + notarization → GitHub Releases + Homebrew cask | Matches the README’s install sections. Avoids App Sandbox friction. |
| Project | Xcode project with a local Swift package `DuoLapseCore` | Core logic is unit-testable via `swift test` without the app target. |
| Tests | Swift Testing | Covers core logic; capture is verified manually. |
| CI | GitHub Actions on a `macos-26` runner: build, test, `swift-format` lint | The cloud dev container is Linux, so CI is the only build check outside a Mac. |

## 2. Architecture

```
DuoLapse.app
├── App/                  @main, scenes, AppDelegate (activation policy, recovery)
├── Features/
│   ├── Library/          session list, open / resume / delete / export
│   ├── Recorder/         active session view, preview, controls
│   ├── Export/           export sheet and progress
│   ├── MenuBar/          MenuBarExtra, timer label, quick access
│   └── Settings/         General, Capture, Export, Shortcuts
└── DuoLapseCore (package)
    ├── Capture/          ScreenSource, CameraSource, CaptureScheduler
    ├── Session/          Session, SessionStore, FrameStore, Recovery
    ├── Export/           FrameSampler, Compositor, TimestampRenderer, VideoWriter
    ├── System/           IdleMonitor, SleepAssertion, LoginItem, Permissions
    └── Naming/           FilenameTemplate
```

### Session on disk

```
~/Library/Application Support/DuoLapse/Sessions/<uuid>/
├── session.json          settings, state, created and updated dates
├── screen/<epoch-ms>.heic
└── camera/<epoch-ms>.heic
```

- Capture timestamps are the filenames. No frame index to corrupt.
- `session.json` is written atomically (`Data.write(options: .atomic)`) on every state change.
- Session states: `recording`, `paused`, `idlePaused`, `finished`.

## 3. Milestones

Each milestone ends in a runnable app and a PR into `alpha`.

### M0: Scaffolding
- Xcode project, `DuoLapseCore` package, app icon placeholder.
- `CLAUDE.md` with build and test commands, conventions and architecture summary (the README already points to it).
- CI workflow, `swift-format` config, `.gitignore`.
- Fill the README sections for Build, Stack and License.

### M1: Screen capture MVP
- Screen Recording permission flow, with an explainer when it’s denied.
- Display picker using `SCShareableContent`.
- `CaptureScheduler`: a `ContinuousClock`-based loop at the user’s interval, which skips (never queues) a tick if the previous capture is still running.
- `FrameStore` writes downscaled HEIC frames off the main actor.
- Start, pause, resume and stop from a single window.

### M2: Webcam
- Camera permission flow and device picker.
- `CameraSource` holds the latest `CVPixelBuffer`, which the scheduler samples on each tick.
- Per-session toggles: screen, camera, or both.

### M3: Export
- `FrameSampler` is a pure function: (frame timestamps, preset) → ordered frame list.
  - Preset frame count = seconds × 30. With more frames than that, it samples evenly. With fewer, it uses every frame and the video comes out shorter, and the UI says so before export.
  - “Full length” uses every frame.
- `Compositor`:
  - Landscape: screen fills the frame, with the camera as a rounded picture-in-picture in a chosen corner.
  - Vertical (9:16): screen on top, camera below. If only one source is enabled, it’s centre-cropped.
- `TimestampRenderer` burns in capture time via `CIAttributedTextImageGenerator`.
- `VideoWriter` uses `AVAssetWriter` + pixel buffer pool, reports progress and supports cancellation.
- Output folder (default `~/Movies/DuoLapse Recordings`), stored as a security-scoped bookmark.
- `FilenameTemplate` handles tokens, preview and sanitising (see §4.4).

### M4: Library and multi-session
- Library window listing sessions with thumbnail, duration, frame count and state.
- Open several sessions. Starting one pauses whichever is recording (`RecordingController` enforces this).
- Delete a session (moved to Trash), re-export.

### M5: Reliability
- **Smart pause:** `IdleMonitor` polls `CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .null)` (any input, no Accessibility permission). It pauses after 60 s idle and resumes on the next input.
- **Keep awake:** `IOPMAssertionCreateWithName` (`PreventUserIdleSystemSleep`, plus `PreventUserIdleDisplaySleep` while capturing the screen). Released on pause, stop and quit.
- **Crash recovery:** on launch, any session left in `recording` is set to `paused` and the app offers to resume it. Frames up to the last completed write survive.
- Disk-space guard: pause and warn below a threshold (e.g. 2 GB free).

### M6: Controls and polish
- `MenuBarExtra` with live elapsed timer and a quick-access menu (start/stop, open session, export, settings).
- Global shortcuts for start, stop and toggle.
- Run on startup toggle.
- Dock icon toggle via `NSApp.setActivationPolicy(.accessory / .regular)`.
- Liquid Glass app icon built in Icon Composer.
- Accessibility pass: VoiceOver labels, keyboard navigation, Reduce Motion.

### M7: Release
- Signing, hardened runtime, notarization in CI on tag.
- Sparkle appcast, GitHub Release, Homebrew cask.
- README install instructions.

## 4. Risks and pushback on the README

### 4.1 Storage grows fast
A 5K display captured every second for 8 hours is about 28,800 frames. At full resolution that’s roughly 30 GB.
**Plan:** store frames at most at 4K (configurable down to 1080p), HEIC quality ~0.7. Show the session’s size in the library.

### 4.2 The webcam stays on
A running `AVCaptureSession` keeps the camera LED on and costs CPU continuously. Starting the camera for each frame avoids that, but each frame then needs ~0.5–1 s of warm-up for auto-exposure and the LED blinks.
**Plan:** keep the session running at a low preset for intervals under 10 s, and start/stop per tick above that. Validate this with measurements in M2.

### 4.3 Smart pause vs keep awake
“Prevent sleep even with smart pause on” is fine for system sleep. Holding a display assertion while idle-paused, though, keeps the screen lit for no captured output. “And devices” has no API meaning beyond the system and the display.
**Plan:** while idle-paused, hold only the system-sleep assertion. Drop “and devices” from the README unless it means something specific.

### 4.4 The default filename contains colons
`DuoLapse Recording YYYY-MM-DDThh:mm:ss` shows `/` in Finder, because `:` is the classic path separator, and it breaks some cloud-sync tools.
**Plan:** default to `DuoLapse Recording YYYY-MM-DD at hh.mm.ss`, matching macOS screenshot naming. Swap any `:` and `/` out when saving.

### 4.5 The “7 minutes” preset
At 30 fps that’s 12,600 frames, which most sessions won’t reach. Under the §M3 rule, those exports come out shorter than 7 minutes. Consider replacing it with `3 minutes` or making presets editable.

### 4.6 The “Duo” layout is unspecified
The README never says how screen and camera combine. §M3 assumes picture-in-picture for landscape and stacked for vertical. This needs confirming before M3.

### 4.7 The dev environment can’t build
This container is Linux. Every build and test runs on the CI macOS runner, so M0’s CI is a hard prerequisite.

## 5. Open questions

1. Is the screen + camera layout in §4.6 correct? Should the camera corner and size be user-adjustable?
2. Is the App Store a goal? It would require the App Sandbox and drop Sparkle. The plan currently targets Developer ID only.
3. License (MIT, GPL-3.0, proprietary)?
4. Should exported videos include audio (silence, a music track)? The current plan is no.
5. Should frames be deleted after export, or kept for re-export? The current plan is to keep them until the user deletes the session.
