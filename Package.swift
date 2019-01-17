// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyFire",
    products: [
        .library(
            name: "SwiftyFire",
            targets: ["SwiftyFire"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/console.git", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "SwiftyFire",
            dependencies: ["Logging"]),
        .testTarget(
            name: "SwiftyFireTests",
            dependencies: ["SwiftyFire"]),
    ]
)
