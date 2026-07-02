// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Xiaomeng",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "XiaomengCore", targets: ["XiaomengCore"]),
        .executable(name: "XiaomengApp", targets: ["XiaomengApp"])
    ],
    dependencies: [],
    targets: [
        .target(name: "XiaomengCore"),
        .executableTarget(
            name: "XiaomengApp",
            dependencies: ["XiaomengCore"]
        ),
        .testTarget(
            name: "XiaomengCoreTests",
            dependencies: ["XiaomengCore"]
        )
    ]
)
