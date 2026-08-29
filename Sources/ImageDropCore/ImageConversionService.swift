import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

public struct ImageConversionService {
    private let rotationAnalyzer: ImageRotationAnalyzer
    private let fileManager: FileManager

    public init(rotationAnalyzer: ImageRotationAnalyzer = .init(), fileManager: FileManager = .default) {
        self.rotationAnalyzer = rotationAnalyzer
        self.fileManager = fileManager
    }

    public func convert(urls: [URL], settings: ConversionSettings) -> [ConversionResult] {
        urls.map { convert(url: $0, settings: settings) }
    }

    public func convert(url: URL, settings: ConversionSettings) -> ConversionResult {
        guard isSupported(url) else {
            return ConversionResult(sourceURL: url, outcome: .skipped(reason: "Unsupported image format"))
        }

        do {
            let inputBytes = try fileSize(at: url)
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let sourceImage = CGImageSourceCreateImageAtIndex(source, 0, [kCGImageSourceShouldCacheImmediately: true] as CFDictionary) else {
                return ConversionResult(sourceURL: url, outcome: .failed(reason: "Could not decode image"))
            }

            let sourceProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] ?? [:]
            let orientation = sourceOrientation(from: sourceProperties)
            var image = try normalizedImage(sourceImage, orientation: orientation)
            var automaticRotation: AutomaticRotation?
            if settings.autoRotateEnabled, let rotation = rotationAnalyzer.suggestedRotation(for: image) {
                image = try rotatedImage(image, radians: rotation.radians)
                automaticRotation = rotation
            }

            image = try resizedImage(image, maximumLongEdge: settings.maxLongEdge)
            let destination = FileNameGenerator.destinationURL(for: url, fileManager: fileManager)
            try writeJPEG(image, to: destination, quality: settings.jpegQuality, removeMetadata: settings.removeMetadata, sourceProperties: sourceProperties)
            let outputBytes = try fileSize(at: destination)
            return ConversionResult(sourceURL: url, outcome: .converted(outputURL: destination, inputBytes: inputBytes, outputBytes: outputBytes, automaticRotation: automaticRotation))
        } catch {
            return ConversionResult(sourceURL: url, outcome: .failed(reason: error.localizedDescription))
        }
    }

    private func isSupported(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension.lowercased()) else { return false }
        return type.conforms(to: .jpeg) || type.conforms(to: .png) || type.identifier == "public.heic" || type.identifier == "public.heif"
    }

    private func sourceOrientation(from properties: [CFString: Any]) -> CGImagePropertyOrientation {
        let value = properties[kCGImagePropertyOrientation] as? UInt32 ?? 1
        return CGImagePropertyOrientation(rawValue: value) ?? .up
    }

    private func normalizedImage(_ image: CGImage, orientation: CGImagePropertyOrientation) throws -> CGImage {
        let swapsDimensions = [.left, .leftMirrored, .right, .rightMirrored].contains(orientation)
        let size = swapsDimensions ? CGSize(width: image.height, height: image.width) : CGSize(width: image.width, height: image.height)
        let context = try makeContext(size: size, colorSpace: image.colorSpace)
        apply(orientation: orientation, in: context, sourceSize: CGSize(width: image.width, height: image.height))
        context.draw(image, in: CGRect(origin: .zero, size: CGSize(width: image.width, height: image.height)))
        guard let result = context.makeImage() else { throw ConversionFailure.renderFailed }
        return result
    }

    private func apply(orientation: CGImagePropertyOrientation, in context: CGContext, sourceSize: CGSize) {
        let w = sourceSize.width
        let h = sourceSize.height
        switch orientation {
        case .up: break
        case .upMirrored: context.translateBy(x: w, y: 0); context.scaleBy(x: -1, y: 1)
        case .down: context.translateBy(x: w, y: h); context.rotate(by: .pi)
        case .downMirrored: context.translateBy(x: 0, y: h); context.scaleBy(x: 1, y: -1)
        case .left: context.translateBy(x: 0, y: w); context.rotate(by: -.pi / 2)
        case .leftMirrored: context.translateBy(x: h, y: w); context.scaleBy(x: -1, y: 1); context.rotate(by: -.pi / 2)
        case .right: context.translateBy(x: h, y: 0); context.rotate(by: .pi / 2)
        case .rightMirrored: context.scaleBy(x: -1, y: 1); context.rotate(by: .pi / 2)
        @unknown default: break
        }
    }

    private func rotatedImage(_ image: CGImage, radians: CGFloat) throws -> CGImage {
        let size = CGSize(width: image.height, height: image.width)
        let context = try makeContext(size: size, colorSpace: image.colorSpace)
        if radians > 0 {
            context.translateBy(x: size.width, y: 0)
        } else {
            context.translateBy(x: 0, y: size.height)
        }
        context.rotate(by: radians)
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard let result = context.makeImage() else { throw ConversionFailure.renderFailed }
        return result
    }

    private func resizedImage(_ image: CGImage, maximumLongEdge: Int?) throws -> CGImage {
        let target = ImageDimensions.resizedSize(for: CGSize(width: image.width, height: image.height), maximumLongEdge: maximumLongEdge)
        guard target.width != CGFloat(image.width) || target.height != CGFloat(image.height) else { return image }
        let context = try makeContext(size: target, colorSpace: image.colorSpace)
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(origin: .zero, size: target))
        guard let result = context.makeImage() else { throw ConversionFailure.renderFailed }
        return result
    }

    private func writeJPEG(_ image: CGImage, to url: URL, quality: Double, removeMetadata: Bool, sourceProperties: [CFString: Any]) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw ConversionFailure.destinationCreationFailed
        }
        // Deliberately add only encoding properties. ImageIO retains the CGImage
        // color space (including ICC data) while no EXIF/GPS/TIFF/IPTC/XMP source metadata is copied.
        var properties = removeMetadata ? [CFString: Any]() : sourceProperties
        if !removeMetadata { properties[kCGImagePropertyOrientation] = 1 }
        properties[kCGImageDestinationLossyCompressionQuality] = quality
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw ConversionFailure.writeFailed }
    }

    private func makeContext(size: CGSize, colorSpace: CGColorSpace?) throws -> CGContext {
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { throw ConversionFailure.contextCreationFailed }
        return context
    }

    private func fileSize(at url: URL) throws -> Int64 {
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(values.fileSize ?? 0)
    }
}

private enum ConversionFailure: LocalizedError {
    case contextCreationFailed, renderFailed, destinationCreationFailed, writeFailed

    var errorDescription: String? {
        switch self {
        case .contextCreationFailed: "Could not create image context"
        case .renderFailed: "Could not render image"
        case .destinationCreationFailed: "Could not create output file"
        case .writeFailed: "Could not write JPEG"
        }
    }
}
