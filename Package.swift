// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Xiaomeng",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "XiaomengCore", targets: ["XiaomengCore"]),
        .library(name: "XiaomengAudio", targets: ["XiaomengAudio"]),
        .library(name: "XiaomengAppCore", targets: ["XiaomengAppCore"]),
        .executable(name: "XiaomengApp", targets: ["XiaomengApp"])
    ],
    dependencies: [],
    targets: [
        .target(name: "XiaomengCore"),
        .target(
            name: "XiaomengAudio",
            dependencies: ["XiaomengCore"]
        ),
        .target(
            name: "XiaomengAppCore",
            dependencies: ["XiaomengCore", "XiaomengAudio"]
        ),
        .executableTarget(
            name: "XiaomengApp",
            dependencies: ["XiaomengAppCore", "XiaomengAudio", "XiaomengCore"]
        ),
        .testTarget(
            name: "XiaomengCoreTests",
            dependencies: ["XiaomengCore"]
        ),
        .testTarget(
            name: "XiaomengAudioTests",
            dependencies: ["XiaomengAudio"]
        ),
        .testTarget(
            name: "XiaomengAppCoreTests",
            dependencies: ["XiaomengAppCore", "XiaomengAudio", "XiaomengCore"]
        )
    ]
)
