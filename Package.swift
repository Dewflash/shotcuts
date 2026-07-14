// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ShortcutBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ShortcutBar", targets: ["ShortcutBar"])
    ],
    targets: [
        .target(name: "ShortcutBarCore"),
        .executableTarget(
            name: "ShortcutBar",
            dependencies: ["ShortcutBarCore"]
        ),
        .testTarget(
            name: "ShortcutBarCoreTests",
            dependencies: ["ShortcutBarCore"]
        )
    ]
)
