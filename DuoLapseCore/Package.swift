// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "DuoLapseCore",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "DuoLapseCore", targets: ["DuoLapseCore"])
    ],
    targets: [
        .target(name: "DuoLapseCore"),
        .testTarget(name: "DuoLapseCoreTests", dependencies: ["DuoLapseCore"]),
    ]
)
