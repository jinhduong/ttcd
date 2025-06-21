// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "PomodoroMenuBar",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-charts", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "PomodoroMenuBar",
            dependencies: [
                .product(name: "Charts", package: "swift-charts")
            ]
        )
    ]
)
