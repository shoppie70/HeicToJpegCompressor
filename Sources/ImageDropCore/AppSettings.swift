import Foundation

public enum LongEdgeOption: Int, CaseIterable, Sendable {
    case pixels1280 = 1280
    case pixels1600 = 1600
    case pixels1980 = 1980
    case pixels2560 = 2560
    case original = 0
    case custom = -1

    public var label: String {
        switch self {
        case .original: "Original"
        case .custom: "Custom"
        default: "\(rawValue) px"
        }
    }
}

public struct ConversionSettings: Equatable, Sendable {
    public static let defaultMaxLongEdge = 1980
    public static let defaultJPEGQuality = 0.85

    public var maxLongEdge: Int?
    public var jpegQuality: Double
    public var removeMetadata: Bool
    public var autoRotateEnabled: Bool

    public init(
        maxLongEdge: Int? = ConversionSettings.defaultMaxLongEdge,
        jpegQuality: Double = ConversionSettings.defaultJPEGQuality,
        removeMetadata: Bool = true,
        autoRotateEnabled: Bool = true
    ) {
        self.maxLongEdge = maxLongEdge
        self.jpegQuality = min(max(jpegQuality, 0), 1)
        self.removeMetadata = removeMetadata
        self.autoRotateEnabled = autoRotateEnabled
    }
}
