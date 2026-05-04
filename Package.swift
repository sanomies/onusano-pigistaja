// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BannerSqueezer",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "BannerSqueezer",
            path: "Sources/BannerSqueezer",
            resources: [
                .process("onusano-splash.mp4"),
                .process("onu-sano-logo.svg"),
                .process("error-bubble.svg"),
                .process("os-confetti.png"),
            ]
        )
    ]
)
