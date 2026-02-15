//
//  TinyTBDeviceClient.swift
//  TinyTBDeviceClient
//
//  Created by Johannes Kinzig on 06.02.2026
//


import Foundation
import NIO
import NIOSSL
import MQTTNIO
import Logging


/// Tiny MQTT Client for ThingsBoard client devices, based on MQTTNIO
/// TLS enabled by default
public class TinyTBDeviceClient {
    // MARK: - Properties
    private let eventLoopGroup: NIOEventLoopGroupProvider
    private let client: MQTTClient
    private let logger: Logger?

    // MARK: - Initializer

    /// Initializes a new instance of `TinyMQTTClient` with the specified configuration.
    ///
    /// - Parameters:
    ///   - host: The hostname or IP address of the MQTT broker.
    ///   - port: The port number to connect to the MQTT broker.
    ///   - clientId: Unique identifier for this client when connecting to the broker.
    ///   - caCertPath: Path to the CA certificate file for SSL/TLS connection.
    ///   - username: Username for authentication with the broker.
    ///   - password: Password for authentication with the broker.
    ///   - eventLoopGroupProvider: The event loop group provider to use for networking operations
    ///   - logger: Optional logger to use for logging messages.
    public init(
        host: String,
        port: Int,
        clientId: String,
        caCertPath: String,
        username: String,
        password: String,
        eventLoopGroupProvider: NIOEventLoopGroupProvider,
        logger: Logger? = nil
    ) throws {
        self.eventLoopGroup = eventLoopGroupProvider
        self.logger = logger

        // TLS Configuration
        let tlsConfig = try Self.createTLSConfiguration(withCertificateAtPath: caCertPath)

        // MQTT Configuration
        let mqttConfig = MQTTClient.Configuration(
            version: .v3_1_1,
            disablePing: false,
            keepAliveInterval: .seconds(30),
            pingInterval: .seconds(40),
            connectTimeout: .seconds(15),
            timeout: .seconds(30),
            userName: username,
            password: password,
            useSSL: true,
            tlsConfiguration: .niossl(tlsConfig),
            sniServerName: nil
        )

        self.client = MQTTClient(
            host: host,
            port: port,
            identifier: clientId,
            eventLoopGroupProvider: eventLoopGroupProvider,
            logger: self.logger,
            configuration: mqttConfig
        )
    }

    deinit {
        try? self.client.syncShutdownGracefully()
    }

    // MARK: - Private Methods

    /// Creates a TLS configuration using the certificate at the specified path.
    ///
    /// - Parameter caCertPath: Path to the CA certificate file for SSL/TLS connection.
    /// - Returns: A configured `TLSConfiguration` instance.
    /// - Throws: An error if the certificate file cannot be read or parsed.
    private static func createTLSConfiguration(withCertificateAtPath caCertPath: String) throws -> TLSConfiguration {
        let caCertData = try Data(contentsOf: URL(fileURLWithPath: caCertPath))
        let caCerts = try NIOSSLCertificate.fromPEMBytes(Array(caCertData))

        var tlsConfig = TLSConfiguration.makeClientConfiguration()
        tlsConfig.trustRoots = .certificates(caCerts)
        tlsConfig.certificateVerification = .fullVerification
        tlsConfig.minimumTLSVersion = .tlsv12

        return tlsConfig
    }

    // MARK: - Public Methods

    /// Establishes a connection to the MQTT broker with the configured credentials.
    ///
    /// - Parameters:
    ///   - cleanSession: Indicates whether to start a new session (true) or resume an existing one (default: true)
    ///   - onSuccess: Closure called when connection is successful (optional).
    ///   - onError: Closure called when connection fails with an error (optional).
    /// - Note: The client must be connected before attempting to publish or subscribe.
    public func connect(
        cleanSession: Bool = true,
        onSuccess: (() -> Void)? = nil,
        onError: ((Error) -> Void)? = nil
    ) {
        self.client.connect(cleanSession: cleanSession).whenComplete { result in
            switch result {
            case .success:
                self.logger?.info("Connected to broker successfully!")
                onSuccess?()
            case .failure(let error):
                self.logger?.error("Error connecting to MQTT broker: \(error)\n\(error.localizedDescription)\n")
                onError?(error)
            }
        }
    }

    /// Disconnects the client from the MQTT broker.
    ///
    /// - Parameters:
    ///   - onSuccess: Closure called when disconnection is successful (optional).
    ///   - onError: Closure called when disconnection fails with an error (optional).
    public func disconnect(
        onSuccess: (() -> Void)? = nil,
        onError: ((Error) -> Void)? = nil
    ) {
        self.client.disconnect().whenComplete { result in
            switch result {
            case .success:
                self.logger?.info("Disconnected from broker, connection closed!")
                onSuccess?()
            case .failure(let error):
                self.logger?.error("Error disconnecting from broker: \(error)\n\(error.localizedDescription)\n")
                onError?(error)
            }
        }
    }

    /// Subscribes the client to the specified MQTT topics.
    ///
    /// - Parameters:
    ///   - topics: Array of topic names to subscribe to.
    ///   - onSuccess: Closure called with the subscribed topics and subscription acknowledgment when successful (optional).
    ///   - onError: Closure called when subscription fails with an error (optional).
    public func subscribe(
        to topics: [String],
        onSuccess: (([String], MQTTSuback) -> Void)? = nil,
        onError: ((Error) -> Void)? = nil
    ) {
        let subscribeTopics = topics.map { MQTTSubscribeInfo(topicFilter: $0, qos: .atLeastOnce) }
        self.client.subscribe(to: subscribeTopics).whenComplete { result in
            switch result {
            case .success(let subAck):
                self.logger?.info("Subscribed to \(topics) successfully!")
                onSuccess?(topics, subAck)
            case .failure(let error):
                self.logger?.error("Error subscribing to topics: \(error)\n\(error.localizedDescription)\n")
                onError?(error)
            }
        }
    }

    /// Publishes a message to the specified MQTT topic.
    ///
    /// - Parameters:
    ///   - message: The message string to publish.
    ///   - topic: The MQTT topic to publish the message to.
    ///   - onSuccess: Closure called when publishing is successful (optional).
    ///   - onError: Closure called when publishing fails with an error (optional).
    public func publish(
        message: String,
        to topic: String,
        onSuccess: (() -> Void)? = nil,
        onError: ((Error) -> Void)? = nil
    ) {
        self.client.publish(
            to: topic,
            payload: ByteBufferAllocator().buffer(string: message),
            qos: .atLeastOnce
        ).whenComplete { result in
            switch result {
            case .success:
                self.logger?.info("Published message \(message) to \(topic) successfully!")
                onSuccess?()
            case .failure(let error):
                self.logger?.error("Error publishing message \(message): \(error)\n\(error.localizedDescription)\n")
                onError?(error)
            }
        }
    }

    /// Registers a listener for incoming messages on subscribed topics.
    ///
    /// - Parameters:
    ///   - name: A unique name for this listener (used internally).
    ///   - onMessage: Closure called with the received message and topic when a message is received (optional).
    ///   - onError: Closure called when an error occurs during message processing (optional).
    public func registerMessageListener(
        named name: String,
        onMessage: ((String, String) -> Void)? = nil,
        onError: ((Error) -> Void)? = nil
    ) {
        client.addPublishListener(named: name) { result in
            switch result {
            case .success(let publishInfo):
                let payloadString = String(buffer: publishInfo.payload)
                self.logger?.info("Received message \(payloadString) for topic \(publishInfo.topicName).")
                onMessage?(payloadString, publishInfo.topicName)
            case .failure(let error):
                onError?(error)
            }
        }
    }

    /// Responds to an RPC request by publishing a response message to the corresponding response topic.
    ///
    /// - Parameters:
    ///   - rpcRequestTopic: The topic from which the RPC request was received.
    ///   - responseMessage: The message to publish as a response.
    ///   - onSuccess: Closure called when the response is published successfully (optional).
    ///   - onError: Closure called when publishing fails with an error (optional).
    public func respondToRPCRequest(
        rpcRequestTopic: String,
        responseMessage: String,
        onSuccess: (() -> Void)? = nil,
        onError: ((Error) -> Void)? = nil
    ) {
        let responseTopic = rpcRequestTopic.replacingOccurrences(of: "request", with: "response")
        self.publish(
            message: responseMessage,
            to: responseTopic,
            onSuccess: onSuccess,
            onError: onError
        )
    }
}
