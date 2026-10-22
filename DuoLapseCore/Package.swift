// swift-tools-version: 6.2

import PackageDescription

var products: [Product] = [
    .library(name: "DuoLapseCore", targets: ["DuoLapseCore"])
]

var targets: [Target] = [
    .target(name: "DuoLapseCore"),
    .testTarget(name: "DuoLapseCoreTests", dependencies: ["DuoLapseCore"]),
]

#if os(macOS)
    products.append(.library(name: "DuoLapseCapture", targets: ["DuoLapseCapture"]))
    targets.append(
        .target(
            name: "DuoLapseCapture",
            dependencies: ["DuoLapseCore"],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances"),
            ]
        )
    )
    products.append(.library(name: "DuoLapseExport", targets: ["DuoLapseExport"]))
    targets.append(.target(name: "DuoLapseExport", dependencies: ["DuoLapseCore"]))
#endif

let package = Package(
    name: "DuoLapseCore",
    platforms: [.macOS(.v26)],
    products: products,
    targets: targets
)
