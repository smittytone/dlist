// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "dlist",
    dependencies: [
        .package(url: "https://github.com/smittytone/clicore", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "dlist",
            dependencies: [
                "Clibudev",
                .product(name: "Clicore", package: "clicore"),
            ],
            path: "dlist",
            exclude: [
                // File not needed for Linux build (so far...)
                "Info.plist",
                "mac_aliases.swift"
            ]
        ),
        .systemLibrary(
            name: "Clibudev",
            path: "clibudev",
            pkgConfig: "libudev"
        )
    ]
)
