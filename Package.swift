// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HeicToJpegCompressor",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "HeicToJpegCompressorCore", targets: ["HeicToJpegCompressorCore"]),
        .executable(name: "HeicToJpegCompressor", targets: ["HeicToJpegCompressorApp"])
    ],
    targets: [
        .target(name: "HeicToJpegCompressorCore"),
        .executableTarget(name: "HeicToJpegCompressorApp", dependencies: ["HeicToJpegCompressorCore"], exclude: ["Info.plist", "Assets.xcassets"]),
        .testTarget(name: "HeicToJpegCompressorCoreTests", dependencies: ["HeicToJpegCompressorCore"])
    ]
)
