// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SwiftUIMacOSPatterns",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "Patterns", targets: ["Patterns"]),
        .executable(name: "PatternsCLI", targets: ["PatternsCLI"]),
    ],
    targets: [
        .target(name: "Patterns"),
        .executableTarget(name: "PatternsCLI", dependencies: ["Patterns"]),
        .testTarget(name: "PatternsTests", dependencies: ["Patterns"]),
    ]
)
