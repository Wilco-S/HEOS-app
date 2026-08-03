// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "HEOSMenuBar",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "HEOSMenuBar", targets: ["HEOSMenuBar"])
    ],
    targets: [
        .executableTarget(
            name: "HEOSMenuBar",
            path: "Sources/HEOSMenuBar"
        ),
        .testTarget(
            name: "HEOSMenuBarTests",
            dependencies: ["HEOSMenuBar"],
            path: "Tests/HEOSMenuBarTests"
        )
    ],
    swiftLanguageModes: [.v5]
)
