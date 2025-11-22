// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PresentationGenerator",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "PresentationGenerator",
            targets: ["PresentationGenerator"]
        )
    ],
    dependencies: [
        // OpenAI SDK - we'll use the official Swift package
        .package(url: "https://github.com/MacPaw/OpenAI.git", from: "0.2.4"),
        // Note: For Word document parsing, we'll need to add a library
        // Options: Use native macOS text extraction or a third-party library
        // For now, we'll plan to use DocumentReader or similar when available
    ],
    targets: [
        .executableTarget(
            name: "PresentationGenerator",
            dependencies: [
                .product(name: "OpenAI", package: "OpenAI"),
            ],
            path: "PresentationGenerator",
            exclude: ["Info.plist"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "PresentationGeneratorTests",
            dependencies: ["PresentationGenerator"],
            path: "PresentationGeneratorTests"
        )
    ]
)
