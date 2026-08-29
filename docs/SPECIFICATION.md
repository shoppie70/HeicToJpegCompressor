# ImageDrop Specification v1.0

## 1. Overview

ImageDrop is a minimal macOS image conversion utility. Its primary use case is converting photos from iPhone / cloud photo services into lightweight JPEG files suitable for web uploads.

The product principle is:

> Drag images onto ImageDrop and receive web-ready JPEG files without opening an editor or configuring settings each time.

The application should stay intentionally small and native. Do not introduce unnecessary frameworks, services, databases, or abstraction layers.

---

## 2. Technology

- Language: Swift
- UI: SwiftUI
- Image decoding / encoding: ImageIO + Core Graphics
- Image orientation analysis: Vision
- Settings: UserDefaults / `@AppStorage`
- App lifecycle: SwiftUI App with AppKit integration where required

Target a reasonably modern macOS version that supports the required SwiftUI and Vision APIs. Prefer the lowest deployment target that does not materially complicate the implementation.

---

## 3. Supported input

Supported image formats:

- HEIC
- HEIF
- JPEG / JPG
- PNG

Unsupported files should be skipped without aborting the entire batch.

Out of scope for v1:

- GIF
- TIFF
- RAW
- PDF
- video

---

## 4. Input methods

The application must support both:

1. Dragging one or more images onto the main application window.
2. Dragging one or more images from Finder onto the application icon in the Dock.

Dropping files should immediately start processing. There should be no separate Convert button.

Dock-based processing should not unnecessarily force the main window to the foreground.

---

## 5. Output rules

### 5.1 Format

Output is always JPEG in v1.

### 5.2 JPEG quality

Default quality:

```text
0.85
```

The setting is user-configurable.

### 5.3 Resize

Default maximum long edge:

```text
1980 px
```

Rules:

- Preserve aspect ratio.
- Never upscale an image that is already smaller than the configured maximum long edge.
- Apply the maximum after orientation normalization.

Examples:

```text
4032 × 3024 -> 1980 × 1485
3024 × 4032 -> 1485 × 1980
1600 × 1200 -> 1600 × 1200
```

### 5.4 Destination

Save the converted image in the same directory as the source image.

Do not show a save dialog during normal conversion.

### 5.5 Filename

Use:

```text
<original-basename>_compressed.jpg
```

Examples:

```text
IMG_1234.HEIC -> IMG_1234_compressed.jpg
IMG_5678.JPG  -> IMG_5678_compressed.jpg
sample.png    -> sample_compressed.jpg
```

If the destination already exists, append a numeric suffix:

```text
IMG_1234_compressed.jpg
IMG_1234_compressed_2.jpg
IMG_1234_compressed_3.jpg
```

The source file must never be overwritten or modified.

---

## 6. Metadata handling

Metadata removal is enabled by default.

When enabled, do not intentionally copy source metadata into the destination JPEG, including:

- EXIF
- GPS
- TIFF metadata
- IPTC
- XMP
- camera / device information
- capture date and other private shooting metadata

Important: orientation must be normalized into the pixel data before metadata is discarded.

Metadata removal must not mean intentionally destroying color fidelity. Preserve or convert color information as needed so that the visual appearance remains suitable for common web usage.

---

## 7. Orientation correction

Orientation handling has two distinct stages and both are required.

### 7.1 Stage 1: metadata orientation normalization

Always perform this stage.

Read the source image orientation and render the image into the visually correct pixel orientation before metadata is removed.

This prevents images that rely on EXIF orientation from becoming rotated after conversion.

This behavior is not user-configurable.

### 7.2 Stage 2: content-based automatic rotation

ImageDrop should also try to correct images that are visually sideways or upside down even when the stored orientation metadata itself appears valid.

Setting:

```text
Automatically correct image orientation
```

Default: ON.

Implementation requirements:

- Run only after Stage 1 normalization.
- Use Apple Vision APIs to analyze image content / horizon orientation.
- Only apply rotations of 90°, -90°, or 180°.
- Be conservative: false-positive rotation is worse than failing to rotate an ambiguous image.
- If confidence is insufficient, keep the image unchanged.
- Vision failure must not fail the conversion itself.

Initial tuning constants should be centralized and easy to adjust during testing. Suggested starting values, not hard contractual values:

```text
rotationConfidenceThreshold = 0.65
angleTolerance = 15 degrees
```

Do not blindly treat those values as correct. Validate the actual Vision API semantics and tune based on real test images.

The implementation should record the applied rotation in the conversion result for debugging / UI feedback.

Potentially ambiguous images include:

- overhead food photography
- isolated products on plain backgrounds
- close-up faces
- sky / walls
- patterns without a clear horizontal reference

For ambiguous cases, do not rotate.

---

## 8. Processing pipeline

For each image:

1. Validate supported input type.
2. Open via ImageIO.
3. Normalize stored orientation into pixel data.
4. If enabled, perform conservative Vision-based automatic rotation.
5. Resize so the long edge does not exceed the configured maximum.
6. Determine a collision-safe destination filename.
7. Encode as JPEG using the configured quality.
8. Do not copy private metadata when metadata removal is enabled.
9. Save beside the source image.
10. Return a conversion result including input size, output size, output URL, status, and applied automatic rotation.

Process batches without loading every full-resolution source image into memory simultaneously. A straightforward sequential implementation is acceptable for v1.

---

## 9. Settings

Expose settings through the standard macOS Settings window (`Command + ,`).

### Maximum long edge

Default: 1980 px.

Provide convenient presets:

- 1280
- 1600
- 1980
- 2560
- Original size
- Custom value

### JPEG quality

- Range: suitable ImageIO quality range (`0.0 ... 1.0`)
- Default: 0.85
- Show the numeric value to the user.

### Remove metadata

- Boolean
- Default: ON

### Automatically correct image orientation

- Boolean
- Default: ON

Persist settings using UserDefaults / `@AppStorage`.

Suggested underlying settings model:

```text
maxLongEdge
jpegQuality
removeMetadata
autoRotateEnabled
```

Do not add configuration for destination directory, output format, or naming strategy in v1.

---

## 10. Main UI

The application should be intentionally minimal.

Initial state should communicate:

- Images can be dropped here.
- HEIC / JPEG / PNG and multiple files are supported.
- Current important conversion settings.

Example summary:

```text
JPEG / max 1980 px / quality 0.85 / metadata removed
```

### Processing state

Show lightweight progress such as:

```text
Converting 3 images...
2 / 5
```

### Completion state

Show:

- successful count
- failed count if any
- skipped count if any
- total source size -> total output size

Example:

```text
5 images converted
12.8 MB -> 2.1 MB
```

A per-file result list is useful but should not turn the UI into a complex image management application.

---

## 11. Notifications

For Dock-based usage, show a macOS notification on completion if practical.

Examples:

```text
5 images converted
12.8 MB -> 2.1 MB
```

or:

```text
4 of 5 images converted, 1 failed
```

Notification support should not block the core implementation if macOS permission handling would significantly complicate the first working version.

---

## 12. Error handling

Failure of one image must not abort the batch.

Expected per-image failures include:

- unsupported input
- corrupt image
- decode failure
- destination write failure
- insufficient file permissions
- JPEG encode failure
- Vision analysis failure

Vision analysis failure is special: fall back to ordinary conversion without Stage 2 automatic rotation.

Return clear but concise errors to the UI.

---

## 13. Suggested project structure

Keep this pragmatic rather than architectural for its own sake.

```text
ImageDrop/
├── ImageDropApp.swift
├── AppDelegate.swift
├── Views/
│   ├── ContentView.swift
│   ├── DropZoneView.swift
│   ├── SettingsView.swift
│   └── ResultListView.swift
├── Models/
│   ├── AppSettings.swift
│   ├── ConversionResult.swift
│   └── ConversionError.swift
├── Services/
│   ├── ImageConversionService.swift
│   ├── ImageRotationAnalyzer.swift
│   ├── FileNameGenerator.swift
│   └── NotificationService.swift
└── Utilities/
```

Adjust this structure if Xcode conventions make a simpler structure preferable. Avoid creating protocols, repositories, coordinators, DI containers, or generic infrastructure without a concrete need.

---

## 14. Acceptance criteria

### Conversion

- HEIC / HEIF can be converted to JPEG.
- JPEG and PNG can also be converted to JPEG.
- Multiple files can be handled in one operation.

### Resize

- Images larger than the configured maximum long edge are reduced correctly.
- Smaller images are not enlarged.
- Aspect ratio is preserved.

### Compression

- Default JPEG quality is 0.85.
- Changing JPEG quality in Settings affects subsequent conversions.

### Metadata

- With metadata removal enabled, private source metadata such as EXIF / GPS is not retained in the destination JPEG.
- Orientation remains visually correct after metadata removal.

### Filename safety

- Output follows `_compressed.jpg` naming.
- Existing destinations cause `_2`, `_3`, etc. to be used.
- Source images are never modified.

### Orientation

- Stored EXIF orientation is normalized correctly.
- Automatic content-based rotation can correct clearly sideways / upside-down images when confidently detected.
- Ambiguous images are left unchanged.
- Vision failure does not prevent successful conversion.

### Interaction

- Window drag-and-drop works.
- Dock icon drag-and-drop works.
- Processing starts without a Convert button.
- Progress / completion feedback is visible.

### Settings

- Maximum long edge can be configured.
- JPEG quality can be configured.
- Metadata removal can be toggled.
- Automatic rotation can be toggled.
- Defaults are 1980 px, 0.85, metadata removal ON, automatic rotation ON.

---

## 15. v1 non-goals

Do not implement these unless this specification is explicitly revised:

- cropping
- manual image rotation UI
- image filters / adjustments
- comparison preview
- WebP / AVIF output
- PNG output
- target file-size mode
- cloud integrations
- history database
- Finder extension
- menu-bar resident app
- codec tuning UI
- configurable output directories
- configurable filename templates

---

## 16. Development principles

- Native and lightweight over cross-platform abstraction.
- Use Apple frameworks before adding third-party dependencies.
- Protect source files above all else.
- Prefer deterministic image processing; make heuristic automatic rotation conservative.
- Keep image-processing logic independent from SwiftUI views so it is testable.
- Build the smallest maintainable implementation that satisfies this specification.
- Do not add future-proof abstractions without a present requirement.
- Keep the public repository free of secrets, tokens, private images, personal data, local absolute paths, signing credentials, and machine-specific configuration.
