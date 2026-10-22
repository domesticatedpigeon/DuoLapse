# DuoLapse Implementation Plan

Native macOS time-lapse recorder for screen and webcam, built from the feature list in `README.md`.

## 1. Decisions

| Area | Choice | Why |
| --- | --- | --- |
| Minimum OS | macOS 26 Tahoe | Liquid Glass icon and materials are a stated feature; avoids `#available` branches everywhere. |
| Language | Swift 6, strict concurrency | Capture, timers and file I/O cross actors; let the compiler catch races. |
| UI | SwiftUI (`Window`, `MenuBarExtra`, `Settings`), AppKit only where SwiftUI has gaps | Native look, small codebase. |
| State | `@Observable` models on the main actor; `TimelapseRecorder` owns one timelapse’s capture loop | Capture and encoding are asynchronous and hardware-backed, so the main actor stays responsive without extra actors. |
| Screen capture | `SCScreenshotManager.captureImage` per tick | Grabs a single frame on demand. No running stream, so near-zero idle cost. |
| Webcam capture | `AVCaptureSession` + `AVCaptureVideoDataOutput` at a throttled frame rate, keep latest frame only | See §4.2. |
| Frame storage | HEVC video segments (fragmented MP4), one track per source, one sample per tick | Smallest on disk by a wide margin; see §4.1. |
| Export | `AVAssetReader` → Core Image compositing → `AVAssetWriter`, HEVC (H.264 fallback), 30 fps | Hardware-encoded, no third-party dependencies. |
| Hotkeys | `KeyboardShortcuts` (sindresorhus) | Proven recorder UI plus global registration. The only third-party runtime dependency. |
| Login item | `SMAppService.mainApp` | Current API; no helper app needed. |
| Updates | Sparkle 2 with EdDSA-signed updates | Works without an Apple Developer membership. |
| Distribution | Self-signed, not notarised → GitHub Releases + Homebrew cask in this repo. No Mac App Store. | No Apple Developer membership. See §7. |
| Project | XcodeGen `project.yml` plus a local Swift package `DuoLapseCore` | A text project spec avoids `.pbxproj` merge conflicts, and core logic is unit-testable via `swift test` without the app target. |
| Tests | Swift Testing | Covers core logic; capture is verified manually. |
| CI | GitHub Actions on a `macos-26` runner: build, test, `swift-format` lint | The cloud dev container is Linux, so CI is the only build check outside a Mac. See §6. |

## 2. Architecture

```
DuoLapse.app
├── App/                  @main, scenes, AppDelegate (activation policy, recovery)
├── Features/
│   ├── Library/          timelapse list, open / resume / delete / export
│   ├── Recorder/         active timelapse view, preview, controls
│   ├── Export/           export sheet, layout picker, progress
│   ├── MenuBar/          MenuBarExtra, timer label, quick access
│   └── Settings/         General, Capture, Export, Shortcuts
└── DuoLapseCore (package)
    ├── Capture/          ScreenSource, CameraSource, CaptureScheduler
    ├── Session/          Session, SessionStore, SegmentWriter, Recovery
    ├── Export/           FrameSampler, LayoutEngine, TimestampRenderer, VideoWriter
    ├── System/           IdleMonitor, PowerAssertions, DisplayStateMonitor, LoginItem, Permissions
    └── Naming/           FilenameTemplate
```

### Timelapse on disk

```
~/Library/Application Support/DuoLapse/Sessions/<uuid>/
├── session.json          settings, state, created and updated dates
├── screen/<start-epoch-ms>.mp4   HEVC segment; sample time = offset from the segment start
└── camera/<start-epoch-ms>.mp4
```

- Each segment is named by the capture time of its first frame, so a frame’s capture time is the segment start plus the frame’s presentation time.
- A new segment starts on every resume, every 10 minutes of recording, and whenever the frame size changes (for example after a display resolution change). Old segments are closed and finalized, so at most the open segment is exposed to a crash.
- The open segment is written as a fragmented MP4 (`movieFragmentInterval` = 10 s). After a crash or power loss it’s readable up to its last fragment.
- `session.json` is written atomically (`Data.write(options: .atomic)`) on every state change.
- Timelapse states: `recording`, `paused`, `idlePaused`, `finished`.
- Frames are kept after export, so a timelapse can be re-exported at any duration or layout. They’re removed only when the user deletes the timelapse from the library. The folder is moved to the Trash, so an accidental delete can be undone; space is freed when the Trash is emptied.

## 3. Milestones

Each milestone ends in a runnable app and a PR into `alpha`.

### M0: Scaffolding
- Xcode project, `DuoLapseCore` package, app icon placeholder.
- `CLAUDE.md` with build and test commands, conventions and architecture summary (the README already points to it).
- CI workflow, `swift-format` config, `.gitignore`.
- Fill the README sections for Build and Stack.

### M1: Screen capture MVP
- Screen Recording permission flow, with an explainer when it’s denied.
- Display picker using `SCShareableContent`. The chosen display is stored by its UUID (`CGDisplayCreateUUIDFromDisplayID`), not its display ID, which can change across sleep and reconnects.
- `CaptureScheduler`: a `ContinuousClock`-based loop at the user’s interval, which skips (never queues) a tick if the previous capture is still running.
- `SegmentWriter` downscales each frame to the storage resolution (§4.1) and appends it to the open HEVC segment, off the main actor.
- Start, pause, resume and stop from a single window.
- Measure storage per hour against the §4.1 budget.

### M2: Webcam
- Camera permission flow and device picker.
- `CameraSource` per §4.2.
- Per-timelapse toggles: screen, camera, or both.

### M3: Export
- `FrameSampler` is a pure function: (frame timestamps, preset) → ordered frame list.
  - Presets: `30 seconds`, `60 seconds`, `3 minutes`, `Full length`, plus a custom duration.
  - Preset frame count = seconds × 30. With more frames than that, it samples evenly. A preset longer than the recording allows is disabled, showing the longest possible length.
  - “Full length” uses every frame.
- `LayoutEngine` per §5.
- `TimestampRenderer` burns in capture time via `CIAttributedTextImageGenerator`.
- `VideoWriter` uses `AVAssetWriter` + pixel buffer pool, reports progress and supports cancellation. No audio track.
- Output folder (default `~/Movies/DuoLapse Recordings`), stored as a security-scoped bookmark.
- `FilenameTemplate` handles tokens, preview and sanitising. Default: `DuoLapse Recording YYYY-MM-DD at hh.mm.ss`. Any `:` or `/` typed by the user is swapped for `.` and `-`.

### M4: Library and multi-session
- Library window listing timelapses with thumbnail, duration, frame count, size on disk and state.
- Open several timelapses. Starting one pauses whichever is recording (`RecordingController` enforces this).
- Close and delete a timelapse (moved to the Trash), re-export.

### M5: Reliability
- **Smart pause:** `IdleMonitor` polls `CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .null)` (any input, no Accessibility permission). It pauses after 60 s idle and resumes on the next input.
- **Keep awake:** see §4.3.
- **Display sleep and wake:** see §4.3.
- **Crash recovery:** on launch, any timelapse left in `recording` is set to `paused`, its open segment is closed out, and the app offers to resume it.
- Disk-space guard: pause and warn below a threshold (e.g. 2 GB free).

### M6: Controls and polish
- `MenuBarExtra` with live elapsed timer and a quick-access menu (start/stop, open timelapse, export, settings).
- Global shortcuts for start, stop and toggle.
- Run on startup toggle.
- Dock icon toggle via `NSApp.setActivationPolicy(.accessory / .regular)`.
- Liquid Glass app icon built in Icon Composer.
- Accessibility pass: VoiceOver labels, keyboard navigation, Reduce Motion.

### M7: Release
- CI on tag: build, sign with the DuoLapse self-signed certificate (§7), zip, publish to GitHub Releases.
- Sparkle appcast signed with an EdDSA key stored as a CI secret.
- `Casks/duolapse.rb` in this repo, bumped by CI on each release.
- Test the README’s first-launch steps on a clean macOS 26 install.

## 4. Technical notes

### 4.1 Storage format and resolution

**Store frames as HEVC video segments, not as individual images.** Consecutive time-lapse frames are nearly identical. Video coding stores only what changed since the previous frame, while any still-image format (HEIC, AVIF, JPEG XL) re-encodes the whole frame every time.

| Format | Per frame, 1080p screen | 8 h at 1 s, screen + camera |
| --- | --- | --- |
| Full-resolution HEIC (old plan) | ~1 MB | ~30 GB |
| 1080p HEIC | ~80–150 KB | ~4–6 GB |
| 1080p AVIF / JPEG XL | ~60–120 KB | ~3–5 GB, and encoding is CPU-only on Mac |
| **1080p HEVC segments** | **~15–40 KB average** | **~1–2 GB** |

Figures are estimates for typical desktop use; M1 measures them. The budget is **≤ 250 MB per recording hour at a 1 s interval**, and proportionally less at longer intervals (about 50 MB per hour at 5 s).

**Storage resolution:**
- Screen: 1920 px on the long edge by default, with an optional “High” setting of 2560 px. Every export layout (§5) fits inside 1920 px, so storing more costs space without improving the default output. “High” is for people who zoom into small text.
- Camera: 1280 × 720.
- Export: 1080p by default (1920 × 1080 landscape, 1080 × 1920 vertical), 1440p when storage is “High”.

HEVC is hardware-encoded on every Mac that runs macOS 26, so encoding one frame per tick costs almost no CPU.

### 4.2 Webcam

A running `AVCaptureSession` keeps the camera light on. Stopping between frames turns the light off but makes it blink each tick, and every frame then needs ~0.5–1 s warm-up for auto-exposure.

**Plan:**
- Keep the session running while recording. The light stays on steadily, which is also the honest privacy signal while the camera is being recorded.
- Throttle the device to its lowest supported frame rate (`activeVideoMinFrameDuration`) at 720p, and keep only the latest frame. This keeps CPU use low.
- Stop the session on pause, idle pause and stop, so the light goes off whenever nothing is being recorded.
- Recover from interruptions (`AVCaptureSession.wasInterruptedNotification`, `runtimeErrorNotification`) and from the device disconnecting, by restarting the session on the same device ID.

### 4.3 Sleep, wake and the webcam

**Keep awake:** while recording, hold `kIOPMAssertPreventUserIdleSystemSleep`. This keeps the Mac and its USB bus, including the webcam, powered. The display is allowed to sleep. The assertion is released on pause, stop and quit. Closing a laptop lid on battery still sleeps the Mac; that can’t be prevented, and is handled like any other sleep below.

**Display sleep and wake:** captures taken while the display is off or the screen is locked would only show black or the lock screen. `DisplayStateMonitor` listens for `NSWorkspace.screensDidSleepNotification` / `screensDidWakeNotification`, system sleep and wake, and screen lock and unlock.
- While the display is asleep or the screen is locked, screen ticks are skipped. Camera-only timelapses keep recording.
- On wake or unlock, before the next screen capture:
  1. Re-fetch `SCShareableContent`, since `SCDisplay` objects can go stale after sleep.
  2. Find the chosen display again by its stored UUID, since its display ID can change.
  3. Take a test capture and check it isn’t blank. If it fails, retry with backoff for up to 30 s, then pause and notify the user.
  4. Restart the camera session if it was interrupted by system sleep.
- Manual test matrix for M5: display sleep, system sleep, lid close, screen lock, external monitor unplugged and replugged, and USB webcam replugged. Each must resume recording without user action.

## 5. Export layouts

The user picks a layout in the export sheet. A preview shows the result before exporting.

### Vertical (1080 × 1920)

Screen and camera are stacked. The user chooses which goes on top.

```
┌──────────┐   ┌──────────┐
│  screen  │   │          │
├──────────┤   │  camera  │
│          │   │          │
│  camera  │   ├──────────┤
│          │   │  screen  │
└──────────┘   └──────────┘
```

- The screen is scaled to the full 1080 px width and keeps its aspect ratio. A 16:10 screen takes 675 px of height, so no screen content is cropped.
- The camera fills the remaining height, centre-cropped. It has no letterboxing.
- Screen only or camera only: the source is fitted and centred on the background colour.

### Horizontal: proposal

**Picture-in-picture (recommended default).** The screen fills the frame, and the camera sits on top in a rounded rectangle. This is the layout Loom and most screen-recording tools use. Screen content is the point of most screen time-lapses, and this keeps all of it at full size.

```
┌───────────────────────────────┐
│                               │
│            screen             │
│                     ┌───────┐ │
│                     │camera │ │
│                     └───────┘ │
└───────────────────────────────┘
```

The user can adjust the overlay:
- Position: one of the four corners of the video, default bottom-right.
- Size: Small, Medium or Large (20%, 25% or 33% of the frame width), default Medium.
- Corner radius: a slider from square corners to fully rounded, default 12% of the overlay’s height.
- Circle: crops the camera to a square and makes it round.

**Side by side (secondary option).** Screen on the left, camera on the right in a vertical strip, centre-cropped. It never covers screen content but shrinks the screen to about 70% of the width.

- The canvas follows the screen’s aspect ratio: 1920 × 1200 for a 16:10 MacBook display, 1920 × 1080 for 16:9. This avoids black bars.
- Screen only or camera only: the source fills the canvas.

## 6. What CI is

CI (continuous integration) is a service that builds the app and runs its tests automatically on every push and pull request. Here it means GitHub Actions running on a Mac machine GitHub provides.

It matters for DuoLapse because this cloud development environment runs Linux. It can’t compile a macOS app, so without CI, nothing is built or tested until someone opens the project in Xcode on a Mac. CI turns every PR into a checked build with a green or red result. Building locally in Xcode still works as normal.

macOS CI is free for public repositories. For private repositories it uses the account’s Actions minutes, and macOS minutes count 10× against the quota.

## 7. Distribution without an Apple Developer membership

- **Gatekeeper:** the app isn’t notarised, so macOS blocks it on first launch. The README explains the one-time **Open Anyway** step and a Terminal fallback.
- **Permissions across updates:** macOS ties Screen Recording and Camera permission to the app’s code signature. An ad-hoc signature changes on every build, which would make users re-grant both permissions after each update. Signing every release with one long-lived self-signed certificate, stored as a CI secret, keeps the signature identity stable so permissions survive updates. M7 verifies this on a real update.
- **Homebrew:** the official Homebrew cask repository no longer accepts apps that fail Gatekeeper, so the cask lives in `Casks/` in this repo. Users tap the repo by its GitHub URL, as in the README. The cask doesn’t strip the quarantine flag, so first launch needs the same **Open Anyway** step as a manual download.
- **Updates:** Sparkle verifies each update with its own EdDSA signature, independent of Apple, so in-app updates work without notarisation.

## 8. License

GPL-3.0. `LICENSE` holds the full text. Both dependencies (KeyboardShortcuts, Sparkle) are MIT, which is GPL-compatible.
