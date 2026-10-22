# App icon source

The DuoLapse icon shows a screen with earlier frames trailing behind it (the time-lapse) and a camera badge. `preview.svg` and `preview.png` show the finished look. Every file is a 1024 × 1024 canvas so the layers line up when imported.

## Layers for Icon Composer

Import these into one group, back to front:

| Order | File | Content | Suggested fill |
| --- | --- | --- | --- |
| 1 | `frames.svg` | Two earlier frames, faded | White at 22% and 48% |
| 2 | `screen.svg` | Current screen | White |
| 3 | `camera.svg` | Camera badge | Coral `#FF5A4E` |
| 4 | `lens.svg` | Lens and highlight | Deep indigo `#24145F` |

Background: a vertical gradient from `#6E5BFF` (top) to `#3423C4` (bottom).

Icon Composer adds the Liquid Glass material, lighting and shadows, so the SVGs contain flat shapes only. Turn on translucency for the frames layer so the background shows through. Leave the other layers opaque.

## Adding it to the app

1. In Icon Composer, save the document as `DuoLapse/Resources/AppIcon.icon`.
2. Delete `DuoLapse/Resources/Assets.xcassets/AppIcon.appiconset`.
3. Run `xcodegen generate` and build. The build setting `ASSETCATALOG_COMPILER_APPICON_NAME` is already `AppIcon`, which matches the `.icon` file name.
