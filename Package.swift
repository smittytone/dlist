// swift-tools-version: 5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "dlist",
    targets: [
        .executableTarget(
            name: "dlist",
            dependencies: ["Clibudev"],
            path: "dlist",
            exclude: [
                // File not needed for Linux build (so far...)
                "Info.plist"    
            ]
        ),
        .systemLibrary(
            name: "Clibudev",
            path: "clibudev",
            pkgConfig: "udev"
        )
    ]
)
