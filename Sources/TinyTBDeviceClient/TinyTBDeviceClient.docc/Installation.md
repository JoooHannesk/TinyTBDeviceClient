# Installation
Installation as Swift PM project

Add the package dependency to your `Package.swift` file:
```swift
// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "YourProject",
    dependencies: [
        .package(url: "https://github.com/JoooHannesk/TinyTBDeviceClient.git", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: "YourProject",
            dependencies: [
                .product(name: "TinyTBDeviceClient", package: "TinyTBDeviceClient"),
            ]
        ),
    ]
)
```
