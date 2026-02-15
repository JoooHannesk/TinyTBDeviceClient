# TinyTBDeviceClient
Tiny MQTT Client for ThingsBoard devices — written in Swift

A minimal, pragmatic MQTT client built on NIO MQTT, pre-configured for ThingsBoard device connectivity. Secure by default through mandatory TLS and CA pinning.

## Intro
- Tiny MQTT client library, designed for client devices working with ThingsBoard
- Built on NIO MQTT (SwiftNIO)
- Pre-configured for ThingsBoard server connectivity
- TLS enabled by default, requires CA pinning
- Runs on macOS, iOS, Linux (successfully tested on Raspberry Pi), and anywhere MQTT-NIO is supported

## Features
- Connect
- Disconect
- Push Telemetry
- Subscribe to topics
- Listen and respond to RPCs (e.g. initiated through buttons and switches on a Dashboard)

## Sample Implementation
A sample implementation making use of this library can be founde here: [TinyTBDeviceClient-Example](https://github.com/JoooHannesk/TinyTBDeviceClient-Example)

## Installation
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
