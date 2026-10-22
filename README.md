# DuoLapse

A simple, native macOS app for recording lightweight time-lapses of your screen and webcam. It captures screenshots at a set interval and automatically stitches them together into a final video. Multiple open time-lapses are supported, with one active recording at a time.

## Features
### Recording & Performance
- **Lightweight:** Low memory and CPU footprint.
- **Multi-source support:** Capture chosen screen with ScreenCaptureKit, and webcam with AVFoundation.
- **Multi-session support:** Keep multiple timelapses open at once, allowing you to easily pause and resume sessions from the library. Note that only one timelapse can be recorded at a time.
- **Custom capture rate:** Select the interval in seconds between screenshots.
- **Smart pause:** Automatically stop and resume recording when no user input is detected for a minute.
- **Keep awake:** Prevents your Mac and webcam from sleeping during recording, even with smart pause on. The display can still sleep, and recording resumes when it wakes.
- **Crash recovery:** Automatically restore your recording session after a crash or power outage.

### Export & Output
- **Built-in exporter:** Stitch screenshots together into a final `30 fps` timelapse.
- **Video export options:** Choose your preferred video duration. Presets are `30 seconds`, `60 seconds`, `3 minutes`, `Full length`, or set a custom duration.
- **Vertical video:** Choose to export videos in a vertical aspect ratio for mobile devices.
- **Storage:** Choose where to save exported videos. The default folder is `~/Movies/DuoLapse Recordings`.
- **Custom filename format:** Define how exported videos are named, with support for dynamic date and time variables. The default is `DuoLapse Recording {YYYY}-{MM}-{DD} at {hh}.{mm}.{ss}`, which gives names like `DuoLapse Recording 2026-10-22 at 15.03.05`
- **Timestamp export:** Include or hide timestamps in your final video.

### Customization & Controls
- **Keyboard shortcut:** Choose custom keyboard shortcuts to start, stop or toggle recording.
- **Menu bar:** Show DuoLapse icon and timer in the menu bar. Clicking on it reveals a Quick Access menu.
- **Run on startup:** Automatically start DuoLapse when you log in.
- **Icon customization:** Liquid Glass support, option to show or hide the app icon from the dock.

## How to Install

Requires macOS 26 Tahoe or later.

### Release

1. Download `DuoLapse.zip` from the [latest release](https://github.com/domesticatedpigeon/DuoLapse/releases/latest).
2. Unzip it and drag `DuoLapse.app` into your `Applications` folder.
3. Open DuoLapse. Follow [Opening DuoLapse for the first time](#opening-duolapse-for-the-first-time) if macOS blocks it.

### Homebrew

```sh
brew tap domesticatedpigeon/duolapse https://github.com/domesticatedpigeon/DuoLapse
brew install --cask duolapse
```

Update with `brew upgrade --cask duolapse`. On first launch, macOS blocks the app the same way as a manual download.

DuoLapse checks for updates automatically. You can also choose **DuoLapse › Check for Updates…** or use the menu bar menu.

### Opening DuoLapse for the first time

DuoLapse isn’t notarised by Apple, so macOS blocks it the first time you open it. You only need to do this once.

1. Open DuoLapse. When macOS says it can’t verify the app, click **Done**.
2. Open **System Settings → Privacy & Security** and scroll down to **Security**.
3. Next to the message about DuoLapse, click **Open Anyway**. The button appears for about an hour after step 1.
4. Enter your Mac password, then click **Open Anyway** again.

If macOS says DuoLapse “is damaged and can’t be opened”, run this in Terminal, then open the app again:

```sh
xattr -dr com.apple.quarantine /Applications/DuoLapse.app
```

### Permissions

On first recording, DuoLapse asks for **Screen & System Audio Recording** and **Camera** access. You can change these later in **System Settings → Privacy & Security**.

## Build

Requires macOS 26 and Xcode 26.

```sh
brew install xcodegen
git clone https://github.com/domesticatedpigeon/DuoLapse.git
cd DuoLapse
xcodegen generate
open DuoLapse.xcodeproj
```

To keep Screen Recording and Camera permission across rebuilds, sign local builds with the project's signing identity and install them with `scripts/install-local.sh`. See “Sign local builds with the same identity” in [`RELEASING.md`](RELEASING.md).

`DuoLapse.xcodeproj` isn’t stored in the repository. `xcodegen generate` creates it in the repository root from `project.yml`. Run it again after pulling changes that touch `project.yml` or add files.

Run the core tests with `swift test --package-path DuoLapseCore`.

## Stack

- Swift 6 and SwiftUI, targeting macOS 26
- ScreenCaptureKit for screen capture, AVFoundation for the webcam and video export
- XcodeGen for the project file, Swift Testing for tests, swift-format for linting
- GitHub Actions for CI

## Development

See [`CLAUDE.md`](CLAUDE.md) for project layout and conventions, and [`PLAN.md`](PLAN.md) for the roadmap.

## License

DuoLapse is licensed under the [GNU General Public License v3.0](LICENSE).
