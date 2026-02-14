// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CliperTube",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "CliperTube", targets: ["CliperTube"])
    ],
    targets: [
        .executableTarget(
            name: "CliperTube",
            path: "Sources/CliperTube"
        )
    ]
)
