// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "PrevineCare",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "PrevineCareCore", targets: ["PrevineCareCore"])
    ],
    targets: [
        .target(
            name: "PrevineCareCore",
            path: "PrevineCare/Core",
            exclude: [
                "Storage/SwiftDataModels.swift"
            ]
        ),
        .testTarget(
            name: "RiskEngineTests",
            dependencies: ["PrevineCareCore"],
            path: "Tests/RiskEngineTests"
        ),
        .testTarget(
            name: "LocationLogicTests",
            dependencies: ["PrevineCareCore"],
            path: "Tests/LocationLogicTests"
        )
    ]
)
