// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AnyGPT",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "AnyGPT", targets: ["AnyGPT"])
    ],
    dependencies: [
        // For better hotkey handling (optional, can use native Carbon instead)
        // .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "AnyGPT",
            dependencies: [],
            path: "AnyGPT",
            exclude: ["Info.plist", "AnyGPT.entitlements"],
            swiftSettings: [
                .unsafeFlags(["-suppress-warnings"])
            ]
        ),
        .testTarget(
            name: "AnyGPTTests",
            dependencies: ["AnyGPT"],
            path: "AnyGPTTests"
        )
    ]
)