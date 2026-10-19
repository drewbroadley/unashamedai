// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WeightingForLife",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "WeightingForLifeCore",
            targets: ["WeightingForLifeCore"]
        ),
        .executable(
            name: "WeightingForLifeVerify",
            targets: ["WeightingForLifeVerify"]
        )
    ],
    targets: [
        .target(
            name: "WeightingForLifeCore",
            path: "Sources/WeightingForLife",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "WeightingForLifeVerify",
            dependencies: ["WeightingForLifeCore"],
            path: "Sources/WeightingForLifeVerify"
        )
    ]
)
