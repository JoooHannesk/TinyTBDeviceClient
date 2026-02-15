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

    var tinyClient: TinyTBDeviceClient? = nil
    let eventLoopGroup: EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let logger = Logger(label: "TinyTBDeviceClient")

    deinit {
        self.tinyClient = nil
    }

    init() throws {
        guard let clientCredentials = ConfigLoader(searchPath: "Credentials").loadClientCredentialsFromFile(fileName: "credentials.json") else {
            fatalError("Unable to read client credentials!")
        }

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

    func connect() async throws -> Bool {
        var connectionSuccess = false
        self.tinyClient?.connect(
            onSuccess: {
                connectionSuccess = true
            },
            onError: { connectionError in
                Issue.record("Failed to connect: \(connectionError)")
            }
        )
        try await Task.sleep(for: .seconds(3))
        try #require(connectionSuccess)
        return connectionSuccess
    }

    func disconnect() async throws -> Bool {
        var disconnectSuccess = false
        self.tinyClient?.disconnect(
            onSuccess: {
                disconnectSuccess = true
            },
            onError: { disconnectError in
                Issue.record("Failed to connect: \(disconnectError)")
            })
        try await Task.sleep(for: .seconds(3))
        try #require(disconnectSuccess)
        return disconnectSuccess
    }

    func subscribe() async throws -> Bool {
        var subscriptionSuccess = false
        self.tinyClient?.subscribe(
            to: ["v1/devices/me/rpc/request/+"],
            onSuccess: { topic, subAck in
                print("✅ Subscribed to \(topic) with \(subAck)")
                subscriptionSuccess = true
            },
            onError: { subscriptionError in
                Issue.record("Failed to subscribe: \(subscriptionError)")
            })
        try await Task.sleep(for: .seconds(3))
        try #require(subscriptionSuccess)
        return subscriptionSuccess
    }
}

@Test("Client can connect")
func canConnect() async throws {
    let clientOUT = try ConnectivityIntegrationCUT()
    let conSuccess = try await clientOUT.connect()
    let disconSuccess = try await clientOUT.disconnect()
    #expect(conSuccess, "Should connect successfully")
    #expect(disconSuccess, "Should disconnect successfully")
}

@Test("Client can subscribe")
func canSubscribe() async throws {
    let clientOUT = try ConnectivityIntegrationCUT()
    let _ = try await clientOUT.connect()
    let subSuccess = try await clientOUT.subscribe()
    let _ = try await clientOUT.disconnect()
    #expect(subSuccess, "Should subscribe successfully")
}
