import Foundation

public enum AutomaticRotation: String, Sendable, Equatable {
    case clockwise90
    case counterClockwise90

    public var radians: CGFloat {
        switch self {
        case .clockwise90: -.pi / 2
        case .counterClockwise90: .pi / 2
        }
    }
}

public enum ConversionOutcome: Sendable, Equatable {
    case converted(outputURL: URL, inputBytes: Int64, outputBytes: Int64, automaticRotation: AutomaticRotation?)
    case skipped(reason: String)
    case failed(reason: String)
}

public struct ConversionResult: Identifiable, Sendable, Equatable {
    public let id = UUID()
    public let sourceURL: URL
    public let outcome: ConversionOutcome

    public init(sourceURL: URL, outcome: ConversionOutcome) {
        self.sourceURL = sourceURL
        self.outcome = outcome
    }
}
