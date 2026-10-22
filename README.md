# DuoLapse

Lightweight time-lapses of your screen and webcam, for macOS.

DuoLapse captures a frame at a set interval and stitches the frames into a video. Keep several time-lapses open and record one at a time.

## Features

**Recording**
- Screen and webcam, previewed side by side
- Capture every few seconds, 2 by default
- Switch display or webcam mid-recording
- Smart pause when you step away
- Keeps your Mac and webcam awake
- Frames survive crashes and power loss

**Library**
- Several open time-lapses, one recording
- Rename, close, reopen or trash
- Keeps running in the menu bar

**Export**
- `30 fps` video, previewed live
- 30 seconds, 1 minute, 3 minutes, full length or custom
- Picture in picture, side by side or vertical
- Fill or fit for each source
- HEVC or H.264
- Optional timestamp
- Custom folder and file name

**Controls**
- Start or pause from anywhere with ⌃⌥⌘R
- Menu bar timer with previews and source switching
- Open at login
- Hide the Dock icon

## Install

Requires macOS 26 Tahoe or later.

**Download:** get `DuoLapse.zip` from the [latest release](https://github.com/domesticatedpigeon/DuoLapse/releases/latest), unzip it and move `DuoLapse.app` to Applications.

**Homebrew:**

```sh
brew tap domesticatedpigeon/duolapse https://github.com/domesticatedpigeon/DuoLapse
brew install --cask duolapse
```

DuoLapse updates itself. You can also choose **DuoLapse › Check for Updates…**.

### First launch

DuoLapse isn’t notarised, so macOS blocks it once.

1. Open DuoLapse and click **Done** when macOS can’t verify it.
2. In **System Settings › Privacy & Security**, click **Open Anyway** next to DuoLapse.
3. Enter your password and click **Open Anyway** again.

If macOS says the app “is damaged”, run this, then open it again:

```sh
xattr -dr com.apple.quarantine /Applications/DuoLapse.app
```

### Permissions

DuoLapse needs **Screen Recording** for your screen and **Camera** for your webcam. Check and grant both in **DuoLapse › Settings › Permissions**. Reopen DuoLapse after allowing Screen Recording.

## Build

Requires Xcode 26.

```sh
brew install xcodegen
git clone https://github.com/domesticatedpigeon/DuoLapse.git
cd DuoLapse
xcodegen generate
open DuoLapse.xcodeproj
```

- Run `xcodegen generate` again after pulling changes to `project.yml` or new files.
- To keep permissions across rebuilds, install with `scripts/install-local.sh`. See [`RELEASING.md`](RELEASING.md).
- Core tests: `swift test --package-path DuoLapseCore`.

Built with Swift 6, SwiftUI, ScreenCaptureKit and AVFoundation. See [`CLAUDE.md`](CLAUDE.md) for conventions and [`PLAN.md`](PLAN.md) for the roadmap.

## License

[GPL-3.0](LICENSE)
