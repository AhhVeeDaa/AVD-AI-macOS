// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Witness",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "AVDCore", targets: ["AVDCore"]),
        .executable(name: "WitnessApp", targets: ["WitnessApp"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AVDCore",
            path: "Sources/AVDCore"
        ),
        .executableTarget(
            name: "WitnessApp",
            dependencies: ["AVDCore"],
            path: "Sources/WitnessApp"
        ),
        .testTarget(
            name: "AVDCoreTests",
            dependencies: ["AVDCore"],
            path: "Tests/AVDCoreTests"
        )
    ]
)
