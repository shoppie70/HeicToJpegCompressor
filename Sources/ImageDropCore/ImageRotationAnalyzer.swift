import CoreGraphics
import Vision

/// A deliberately narrow, content-based correction pass.
///
/// Vision's horizon request reports a horizon angle, but no confidence and no
/// semantic indication of which end is up. Consequently it cannot safely
/// distinguish a 180-degree error. We only use a detected horizon that is
/// nearly vertical to correct an obvious 90-degree error; all other images
/// remain unchanged. Validate this manually with landscape, portrait, and
/// ambiguous product/overhead photos before changing the tolerance.
public struct ImageRotationAnalyzer: Sendable {
    public static let rightAngleTolerance: CGFloat = 15 * .pi / 180

    public init() {}

    public func suggestedRotation(for image: CGImage) -> AutomaticRotation? {
        let request = VNDetectHorizonRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])

        do {
            try handler.perform([request])
            guard let angle = request.results?.first?.angle else { return nil }
            let magnitude = abs(angle)
            guard abs(magnitude - (.pi / 2)) <= Self.rightAngleTolerance else { return nil }
            return angle > 0 ? .clockwise90 : .counterClockwise90
        } catch {
            return nil
        }
    }
}
