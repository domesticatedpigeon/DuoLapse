# App icon source

A graphite screen with a pink recording dot on its corner, on a light neutral background. `preview.svg` and `preview.png` show the finished look. Every file is a 1024 × 1024 canvas so the layers line up when imported.

## Layers for Icon Composer

Import these into one group, back to front:

| Order | File | Content | Fill |
| --- | --- | --- | --- |
| 1 | `screen.svg` | Screen | Graphite `#2C2C2E` |
| 2 | `dot.svg` | Recording dot | Pink `#FF4F8B` |

Background: a vertical gradient from `#F5F5F3` (top) to `#DEDEDA` (bottom).

Icon Composer adds the Liquid Glass material, lighting and shadows, so the SVGs contain flat shapes only. Keep both layers opaque. The dot sits on its own layer, so Icon Composer gives it a little depth over the screen.

## Adding it to the app

1. In Icon Composer, save the document as `DuoLapse/Resources/AppIcon.icon`.
2. Delete `DuoLapse/Resources/Assets.xcassets/AppIcon.appiconset`.
3. Run `xcodegen generate` and build. The build setting `ASSETCATALOG_COMPILER_APPICON_NAME` is already `AppIcon`, which matches the `.icon` file name.
