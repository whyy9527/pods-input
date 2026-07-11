// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PodsInput",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "PodsInputCore",
            targets: ["PodsInputCore"]
        ),
        .executable(
            name: "pods-input",
            targets: ["PodsInput"]
        ),
        .executable(
            name: "pods-input-self-test",
            targets: ["PodsInputSelfTest"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.60.0"),
    ],
    targets: [
        .executableTarget(
            name: "PodsInput",
            dependencies: [
                "PodsInputCore",
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOWebSocket", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
            ],
            path: "Sources"
        ),
        .target(
            name: "PodsInputCore",
            path: "Core"
        ),
        .executableTarget(
            name: "PodsInputSelfTest",
            dependencies: ["PodsInputCore"],
            path: "SelfTest"
        ),
    ]
)
