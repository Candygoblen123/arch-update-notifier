// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "arch-update-notifier",
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "arch-update-notifier",
            dependencies: [.target(name: "Gio")]),
        .systemLibrary(name: "Gio", pkgConfig: "gio-2.0"),
    ]
)
