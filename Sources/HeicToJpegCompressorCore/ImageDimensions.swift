import CoreGraphics

public enum ImageDimensions {
    public static func resizedSize(for size: CGSize, maximumLongEdge: Int?) -> CGSize {
        guard let maximumLongEdge, maximumLongEdge > 0 else { return size }
        let longEdge = max(size.width, size.height)
        guard longEdge > CGFloat(maximumLongEdge) else { return size }

        let scale = CGFloat(maximumLongEdge) / longEdge
        return CGSize(
            width: max(1, (size.width * scale).rounded(.toNearestOrAwayFromZero)),
            height: max(1, (size.height * scale).rounded(.toNearestOrAwayFromZero))
        )
    }
}
