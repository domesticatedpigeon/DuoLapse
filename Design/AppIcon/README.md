# App icon source

The shipped icon is `DuoLapse/Resources/AppIcon.icon`, exported from Icon Composer. That file is the source of truth for colours, glass and appearance variants. The SVGs here are the original layer artwork it was built from.

A graphite screen with a pink recording dot on its corner, on a light neutral background. Inside the screen, a strip of four frames brightens towards the dot, suggesting time passing up to the moment being recorded. `preview.svg` and `preview.png` show the finished look. Every file is a 1024 × 1024 canvas so the layers line up when imported.

## Layers for Icon Composer

Import these into one group, back to front:

| Order | File | Content | Fill |
| --- | --- | --- | --- |
| 1 | `screen.svg` | Screen | Graphite `#2C2C2E` |
| 2 | `frames.svg` | Frame strip | Off-white `#F5F5F3` at 20%, 40%, 65% and 90% |
| 3 | `dot.svg` | Recording dot | Pink `#FF4F8B` |

Background: a vertical gradient from `#F5F5F3` (top) to `#DEDEDA` (bottom).

Icon Composer adds the Liquid Glass material, lighting and shadows, so the SVGs contain flat shapes only. Keep the screen and dot layers opaque. The dot sits on its own layer, so Icon Composer gives it a little depth over the screen.

## Updating the icon

Open `DuoLapse/Resources/AppIcon.icon` in Icon Composer, edit, and save it in place. Keep the name `AppIcon.icon`: it must match the build setting `ASSETCATALOG_COMPILER_APPICON_NAME`. CI checks that the built app contains the compiled icon.
