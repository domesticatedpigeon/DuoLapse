# App icon source

The shipped icon is `DuoLapse/Resources/AppIcon.icon`, an Icon Composer document. It's the source of truth for colours, glass and appearance variants. The files here are its artwork.

A hand-drawn smiling face: two closed, happy eyes in graphite and a pink smile, on the system's light background. `drawing.webp` is the original drawing; `eyes.svg` and `smile.svg` are smoothed vector traces of it on a 1024 × 1024 canvas, and `preview.svg` / `preview.png` show the finished look.

## Layers

| Order | File | Content | Fill |
| --- | --- | --- | --- |
| 1 | `smile.svg` | Smile | Pink `#FF4F8B` |
| 2 | `eyes.svg` | Eyes | Graphite `#1C1C1E`, light in dark mode |

Icon Composer adds the Liquid Glass material, lighting and shadows, so the SVGs contain flat shapes only.

## Updating the icon

Open `DuoLapse/Resources/AppIcon.icon` in Icon Composer, edit, and save it in place. Keep the name `AppIcon.icon`: it must match the build setting `ASSETCATALOG_COMPILER_APPICON_NAME`. CI checks that the built app contains the compiled icon.

## Menu bar icon

`DuoLapse/Resources/Assets.xcassets/MenuBarIcon.imageset/MenuBarIcon.svg` brings the earlier icons together at 18 × 18 points: the rounded screen of the first icon, the smiling face of the current one, and the recording dot on the screen's corner, with the outline stopping short of the dot so it reads as a separate shape. It's a template image, so macOS tints it to match the menu bar.
