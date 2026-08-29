// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ImageDrop",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ImageDropCore", targets: ["ImageDropCore"]),
        .executable(name: "ImageDrop", targets: ["ImageDropApp"])
    ],
    targets: [
        .target(name: "ImageDropCore"),
        .executableTarget(name: "ImageDropApp", dependencies: ["ImageDropCore"], exclude: ["Info.plist", "Assets.xcassets"]),
        .testTarget(name: "ImageDropCoreTests", dependencies: ["ImageDropCore"])
    ]
)
