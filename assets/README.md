# HEICをJPEGへ縮小圧縮するだけ DMG background

`dmg-background.png` is the Finder background used by `scripts/build_dmg.sh`.
The editable source is `dmg-background.svg` so the release asset can be
reproduced without a design-tool dependency.

`build_dmg.sh` uses `create-dmg` on macOS 15 and earlier. On macOS 26 and
later it uses `dmgbuild`, because Tahoe Finder no longer persists background
images configured through the AppleScript mechanism used by `create-dmg`.
When packaging locally on macOS 26 or later, install the fallback with:

```sh
brew install pipx
pipx install "dmgbuild==1.6.7"
```

`dmgbuild` stores the image as a Finder-hidden `.background.png` in the DMG.
It stays out of the normal installer view. If a developer has explicitly
enabled Finder's global hidden-file display, Finder will intentionally show it
faded; press `Command + Shift + .` to return to the normal view before visual
QA. This preference cannot be overridden safely for only one DMG window.

## Canvas and export settings

- Logical background canvas: **660 × 400 pt**
- Finder window on macOS 15 and earlier: **660 × 400 pt**
- Finder window on macOS 26 and later: **840 × 400 pt** (includes 180 pt for
  the sidebar that Tahoe may preserve from the user's Finder settings)
- Retina export: **1320 × 800 px** (`@2x`)
- Color space: sRGB
- File format: PNG, without indexed-color conversion
- Keep the entire canvas opaque so Finder appearance settings do not show
  through it.

The committed PNG is ready to use and is not regenerated during packaging.
To regenerate it from the editable SVG with optional ImageMagick:

```sh
magick -background '#F3F6FF' assets/dmg-background.svg \
  -alpha off -depth 8 PNG24:assets/dmg-background.png
sips -s dpiWidth 144 -s dpiHeight 144 assets/dmg-background.png
```

Verify the exported dimensions with:

```sh
sips -g pixelWidth -g pixelHeight -g dpiWidth -g dpiHeight \
  assets/dmg-background.png
```

## Layout specification

Coordinates below are Finder points measured from the top-left. Pixel values
in parentheses are doubled for the Retina canvas.

| Element | Center / bounds in points | Retina pixels |
| --- | --- | --- |
| `HeicToJpegCompressor.app` Finder icon | center `(180, 140)` | `(360, 280)` |
| Direction arrow | from about `(260, 140)` to `(400, 140)` | `(520, 280)` to `(800, 280)` |
| `Applications` Finder link | center `(480, 140)` | `(960, 280)` |
| Help banner | bounds `(48, 252, 564, 100)` | `(96, 504, 1128, 200)` |

The app and Applications icons and their labels are supplied by Finder and must
**not** be baked into the background. The background only provides the
directional arrow, icon landing areas, and first-launch help banner. Keep
roughly 120 pt of clear space around each Finder icon center.

The help copy is:

> 開けない場合: システム設定 ＞ プライバシーとセキュリティ ＞［このまま開く］をクリック

If recreating the source in Figma or Photoshop, use a 1320 × 800 px frame and
place all measurements at exactly 2× the logical coordinates above. Preserve
the top icon area and the lower help banner as separate groups so the Finder
positions can be adjusted without redesigning the notice.
