// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "avd-ai-macos",
    dependencies: [],
    targets: [
        .executableTarget(name: "AVDCore", path: "Sources/AVDCore"),
        .executableTarget(name: "WitnessApp", path: "Sources/WitnessApp")
    ]
)