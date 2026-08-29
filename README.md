# ImageDrop

ImageDrop is a minimal macOS utility for converting photos into lightweight JPEG files suitable for web uploads.

The core interaction is intentionally simple: drag one or more images onto the app window or Dock icon and ImageDrop converts them automatically.

## Planned behavior

- Native macOS app built with SwiftUI
- HEIC / HEIF / JPEG / PNG input
- JPEG output
- Default maximum long edge: 1980 px
- Default JPEG quality: 0.85
- Metadata removal enabled by default
- Automatic orientation correction
- Multiple-file batch processing
- Output saved next to the source file as `*_compressed.jpg`
- Source files are never modified

See [`docs/SPECIFICATION.md`](docs/SPECIFICATION.md) for the implementation specification.

## Project status

v1 implementation is available in the Xcode project (`ImageDrop.xcodeproj`).

### Orientation correction note

Stored EXIF orientation is always rendered into the output pixels before encoding.
The optional Vision pass uses `VNDetectHorizonRequest` only when it detects a
horizon that is nearly vertical, which is a conservative signal for a 90-degree
error. Vision does not provide a confidence score or enough semantic information
to safely distinguish an upside-down (180-degree) image, so ImageDrop leaves
those images unchanged. Before widening this heuristic, manually validate clear
landscape/portrait scenes as well as overhead food, product, close-up face, and
pattern images; false-positive rotation is worse than leaving an image unchanged.
