// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "SwiftUIMacOSPatterns",
  platforms: [
    .macOS(.v15)
  ],
  products: [
    .library(name: "Patterns", targets: ["Patterns"]),
    .executable(name: "PatternsCLI", targets: ["PatternsCLI"]),
  ],
  targets: [
    .target(
      name: "Patterns",
      swiftSettings: [
        // Keep examples maximally useful for modern macOS SwiftUI targets.
        .defaultIsolation(MainActor.self)
      ]
    ),
    .executableTarget(name: "PatternsCLI", dependencies: ["Patterns"]),
    .testTarget(name: "PatternsTests", dependencies: ["Patterns"]),
  ]
)
