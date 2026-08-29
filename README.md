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

Initial specification phase. Implementation has not started yet.
