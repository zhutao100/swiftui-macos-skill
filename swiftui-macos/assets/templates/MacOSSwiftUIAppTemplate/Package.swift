// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "MacOSSwiftUIAppTemplate",
  platforms: [
    .macOS(.v15)
  ],
  products: [
    .executable(name: "AppTemplate", targets: ["AppTemplate"])
  ],
  targets: [
    .executableTarget(
      name: "AppTemplate",
      swiftSettings: [
        .defaultIsolation(MainActor.self)
      ]
    )
  ]
)
