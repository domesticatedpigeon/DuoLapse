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
- **Custom filename format:** Define how exported videos are named, with support for dynamic date and time variables. The default is `DuoLapse Recording YYYY-MM-DD at hh.mm.ss`
- **Timestamp export:** Include or hide timestamps in your final video.

### Customization & Controls
- **Keyboard shortcut:** Choose custom keyboard shortcuts to start, stop or toggle recording.
- **Menu bar:** Show DuoLapse icon and timer in the menu bar. Clicking on it reveals a Quick Access menu.
- **Run on startup:** Automatically start DuoLapse when you log in.
- **Icon customization:** Liquid Glass support, option to show or hide the app icon from the dock.

## How to Install

Install instructions go here.

### Release

### Homebrew

## Build

Build goes here.

## Stack

Stack goes here.

## Development

`CLAUDE.md`

## License

License goes here.
