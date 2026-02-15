import NIO
import Foundation
import Logging

import Testing
@testable import TinyTBDeviceClient


/// TinyTBDeviceClient Integration tests
///
/// Simple connectivity integration tests to check if basic functionality is working.
/// For a detailed and sample implementation, refer to https://github.com/JoooHannesk/TinyTBDeviceClient-Example
class ConnectivityIntegrationCUT {

    var testTimeout: Duration = .seconds(1)
    var tinyClient: TinyTBDeviceClient? = nil
    let eventLoopGroup: EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let logger = Logger(label: "TinyTBDeviceClient")
    static let clientCredentials: MQTTClientCredentials = ConfigLoader(searchPath: "Credentials").loadClientCredentialsFromFile(fileName: "credentials.json")!


    deinit {
        self.tinyClient = nil
    }

    init(clientCredentials: MQTTClientCredentials = ConnectivityIntegrationCUT.clientCredentials) throws {
        do {
            self.tinyClient = try TinyTBDeviceClient(
                host: clientCredentials.host,
                port: clientCredentials.port,
                clientId: clientCredentials.clientId,
                caCertPath: clientCredentials.caCertPath,
                username: clientCredentials.username,
                password: clientCredentials.password,
                eventLoopGroupProvider: .shared(eventLoopGroup),
                logger: logger
            )
        } catch {
            fatalError("Unable to initialize client: \(error)")
        }
        try #require(self.tinyClient != nil)
    }


    func listen() async throws -> Bool {
        var registerListenerSuccess = true
        self.tinyClient?.registerMessageListener(named: "Message-Listener", onError:  { error in
            registerListenerSuccess = false
        })
        try await Task.sleep(for: testTimeout)
        try #require(registerListenerSuccess)
        return registerListenerSuccess
    }

    func connect() async throws -> Bool? {
        var connectionSuccess: Bool? = nil
        self.tinyClient?.connect(
            onSuccess: {
                connectionSuccess = true
            },
            onError: { connectionError in
                connectionSuccess = false
            }
        )
        try await Task.sleep(for: testTimeout)
        try #require(connectionSuccess != nil)
        return connectionSuccess
    }

    func disconnect() async throws -> Bool? {
        var disconnectSuccess: Bool? = nil
        self.tinyClient?.disconnect(
            onSuccess: {
                disconnectSuccess = true
            },
            onError: { disconnectError in
                disconnectSuccess = false
            })
        try await Task.sleep(for: testTimeout)
        try #require(disconnectSuccess != nil)
        return disconnectSuccess
    }

    func subscribe() async throws -> Bool? {
        var subscriptionSuccess: Bool? = nil
        self.tinyClient?.subscribe(
            to: ["v1/devices/me/rpc/request/+"],
            onSuccess: { topic, subAck in
                print("✅ Subscribed to \(topic) with \(subAck)")
                subscriptionSuccess = true
            },
            onError: { subscriptionError in
                subscriptionSuccess = false
            })
        try await Task.sleep(for: testTimeout)
        try #require(subscriptionSuccess != nil)
        return subscriptionSuccess
    }

    func publish() async throws -> Bool? {
        var publishSuccess: Bool? = nil
        self.tinyClient?.publish(
            message: #"{ "testMessage": "Hello ThingsBoard at \#(Date())"}"#,
            to: "v1/devices/me/telemetry",
            onSuccess: {
                print("✅ Published message")
                publishSuccess = true
            },
            onError: { publishError in
                publishSuccess = false
            })
            try await Task.sleep(for: testTimeout)
            try #require(publishSuccess != nil)
            return publishSuccess
    }
}

@Test("Client-Connects")
func canConnect() async throws {
    let clientOUT = try ConnectivityIntegrationCUT()
    let listenerRegistered = try await clientOUT.listen()
    let conSuccess = try await clientOUT.connect()
    let disconSuccess = try await clientOUT.disconnect()
    #expect(listenerRegistered, "Listener should have been registered")
    #expect(conSuccess!, "Should connect successfully")
    #expect(disconSuccess!, "Should disconnect successfully")
}

@Test("Client-Cannot-Connect")
func cannotConnect() async throws {
    let nonWorkingCredentials = MQTTClientCredentials(host: "test.mosquitto.org", port: 8883, caCertPath: "/etc/ssl/cert.pem", clientId: "NoID", username: "NoUsr", password: "NoPassword")
    let clientOUT = try ConnectivityIntegrationCUT(clientCredentials: nonWorkingCredentials)
    let conSuccess = try await clientOUT.connect()
    #expect(!conSuccess!, "Should not connect successfully")
}

@Test("Client-Subscribes")
func canSubscribe() async throws {
    let clientOUT = try ConnectivityIntegrationCUT()
    let _ = try await clientOUT.connect()
    let subSuccess = try await clientOUT.subscribe()
    let _ = try await clientOUT.disconnect()
    #expect(subSuccess!, "Should subscribe successfully")
}

@Test("Client-Cannot-Subscribe")
func cannotSubscribe() async throws {
    let clientOUT = try ConnectivityIntegrationCUT()
    let subSuccess = try await clientOUT.subscribe()
    #expect(!subSuccess!, "Should not subscribe successfully")
}

@Test("Client-Publishes")
func canPublish() async throws {
    let clientOUT = try ConnectivityIntegrationCUT()
    let _ = try await clientOUT.connect()
    let pubSuccess = try await clientOUT.publish()
    let _ = try await clientOUT.disconnect()
    #expect(pubSuccess!, "Should publish successfully")
}

@Test("Client-Cannot-Publish")
func cannotPublish() async throws {
    let clientOUT = try ConnectivityIntegrationCUT()
    let pubSuccess = try await clientOUT.publish()
    #expect(!pubSuccess!, "Should not publish successfully")
}
