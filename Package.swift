// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TinyTBDeviceClient",
    platforms: [
        .macOS(.v13),
        .iOS(.v17),
        .custom("Linux", versionString: "6.12.34")
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TinyTBDeviceClient",
            targets: ["TinyTBDeviceClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server-community/mqtt-nio.git", from: "2.13.0")    // Apache-2.0 License
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TinyTBDeviceClient",
            dependencies: [
                .product(name: "MQTTNIO", package: "mqtt-nio"),
            ],
        ),
        .testTarget(
            name: "TinyTBDeviceClientTests",
            dependencies: ["TinyTBDeviceClient"]
        ),
    ]
)
