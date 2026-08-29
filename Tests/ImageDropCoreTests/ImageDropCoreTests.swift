import CoreGraphics
import Foundation
import ImageDropCore
import ImageIO
import Testing

@Suite("ImageDrop conversion utilities")
struct ImageDropCoreTests {
    @Test func resizePreservesAspectRatio() {
        #expect(ImageDimensions.resizedSize(for: CGSize(width: 4032, height: 3024), maximumLongEdge: 1980) == CGSize(width: 1980, height: 1485))
        #expect(ImageDimensions.resizedSize(for: CGSize(width: 3024, height: 4032), maximumLongEdge: 1980) == CGSize(width: 1485, height: 1980))
    }

    @Test func resizeNeverUpscales() {
        #expect(ImageDimensions.resizedSize(for: CGSize(width: 1600, height: 1200), maximumLongEdge: 1980) == CGSize(width: 1600, height: 1200))
        #expect(ImageDimensions.resizedSize(for: CGSize(width: 1600, height: 1200), maximumLongEdge: nil) == CGSize(width: 1600, height: 1200))
    }

    @Test func settingsHaveV1Defaults() {
        let settings = ConversionSettings()
        #expect(settings.maxLongEdge == 1980)
        #expect(settings.jpegQuality == 0.85)
        #expect(settings.removeMetadata)
        #expect(settings.autoRotateEnabled)
    }

    @Test func fileNamesAvoidExistingDestinations() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = directory.appendingPathComponent("IMG_1234.HEIC")
        #expect(FileNameGenerator.destinationURL(for: source).lastPathComponent == "IMG_1234_compressed.jpg")
        FileManager.default.createFile(atPath: directory.appendingPathComponent("IMG_1234_compressed.jpg").path, contents: Data())
        #expect(FileNameGenerator.destinationURL(for: source).lastPathComponent == "IMG_1234_compressed_2.jpg")
    }

    @Test func conversionPreservesSourceAndNormalizesExifOrientation() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = directory.appendingPathComponent("oriented.jpg")
        try orientedJPEG().write(to: source)
        let original = try Data(contentsOf: source)
        let result = ImageConversionService().convert(url: source, settings: ConversionSettings(autoRotateEnabled: false))
        guard case let .converted(output, _, _, _) = result.outcome else { Issue.record("Expected conversion"); return }
        #expect(try Data(contentsOf: source) == original)
        let image = CGImageSourceCreateWithURL(output as CFURL, nil).flatMap { CGImageSourceCreateImageAtIndex($0, 0, nil) }
        #expect(image?.width == 20)
        #expect(image?.height == 40)
        let properties = CGImageSourceCopyPropertiesAtIndex(CGImageSourceCreateWithURL(output as CFURL, nil)!, 0, nil) as? [CFString: Any]
        #expect(properties?[kCGImagePropertyOrientation] == nil)
    }

    private func orientedJPEG() throws -> Data {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let context = CGContext(data: nil, width: 40, height: 20, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1)); context.fill(CGRect(x: 0, y: 0, width: 40, height: 20))
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "public.jpeg" as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, context.makeImage()!, [kCGImagePropertyOrientation: 6] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        return data as Data
    }
}
