// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "nyc-tui",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/rensbreur/SwiftTUI", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "nyc-tui",
            dependencies: ["SwiftTUI"],
            path: ".",
            sources: ["Sources/Models/BuildingModel.swift", "Sources/Models/ResourceModel.swift", "tui/main.swift"]
        )
    ]
)
