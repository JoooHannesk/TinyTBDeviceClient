import NIO
import Foundation
import Logging

import Testing
@testable import TinyTBDeviceClient


class ConnectivityTest {

    var tinyClient: TinyTBDeviceClient? = nil
    let eventLoopGroup: EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let logger = Logger(label: "TinyTBDeviceClient")

    func setupClient() throws {
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

    @Test("Client can connect")
    func canConnect() async throws {
        try self.setupClient()
        let success = try await connect()
        self.tinyClient?.disconnect()
        //if !success { try await eventLoopGroup.shutdownGracefully() }
        #expect(success, "Should connect successfully")
    }
}
