# TinyTBDeviceClient
Tiny MQTT Client for ThingsBoard devices — written in Swift

A minimal, pragmatic MQTT client built on top of NIO MQTT, pre-configured for ThingsBoard device connectivity. Secure by default through mandatory TLS and CA pinning.

## 🥾 Motivation
This library provides a simplified interface for connecting IoT devices to ThingsBoard using MQTT. It handles the common tasks such as publishing telemetry messages (time-series data), subscribing to topics (e.g. attribute changes), and handling RPC requests. The goal is to reduce the complexity of MQTT when integrating IoT devices with ThingsBoard, offering a more focused and manageable approach.

## 📱 Summary
- Tiny MQTT client library, designed for IoT client devices working with ThingsBoard
- Built on top of NIO MQTT (SwiftNIO)
- Pre-configured for ThingsBoard server connectivity
- TLS enforced by default, requires CA pinning
- Runs on macOS, iOS, Linux (successfully tested on Raspberry Pi), and anywhere MQTT-NIO is supported

## 📝 Further Readings
- Library Documentation: [TinyTBDeviceClient Docs](https://tinytbdeviceclient.kinzig-developer-docs.com/documentation/tinytbdeviceclient)
- Sample implementation making use of this library: [TinyTBDeviceClient-Example](https://github.com/JoooHannesk/TinyTBDeviceClient-Example)
- Additional information on my blog: [TinyTBDeviceClient](https://johanneskinzig.com/tinytbdeviceclient.html)

## 💻 Features
- Connect
- Disconect
- Push Telemetry
- Subscribe to topics
- Listen and respond to RPCs (e.g. initiated through buttons and switches on a Dashboard)

## 🔐 SSL / TLS
In case you need to set up your own PKI for your MQTT or ThingsBoard server, look at the related post on my blog: [Building a Secure PKI for MQTT using OpenSSL](https://johanneskinzig.com/building-a-secure-pki-for-mqtt-using-openssl-root-ca-intermediate-ca-and-server-certificates.html)

## 💾 Installation
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

## 📑 License
- Apache 2.0 License
- Copyright (c) 2026 Johannes Kinzig
- see LICENSE
