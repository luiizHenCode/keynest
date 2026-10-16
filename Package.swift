// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacTap",
    defaultLocalization: "pt-BR",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "MacTap", targets: ["MacTap"])],
    targets: [
        .executableTarget(name: "MacTap", resources: [
                    .copy("Resources/KeyboardSounds"),
                    .copy("Resources/Ambience"),
                                        .process("Resources/Localization")
                ]),
        .testTarget(name: "MacTapTests", dependencies: ["MacTap"])
    ],
    swiftLanguageModes: [.v5]
)
