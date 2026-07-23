/*
 Copyright 2020 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

/// This enum includes custom errors that can be returned by the SDK when using the `NetworkService` with completion handler.
public enum NetworkServiceError: Error {
    case invalidUrl
}

class NetworkService: Networking, NetworkAvailabilityProviding {
    private let LOG_PREFIX = "NetworkService"

    private var sessionsQueue = DispatchQueue(label: "com.adobe.networkService.sessions")
    private var sessions: [String: URLSession] = [:]

    // MARK: - Network availability

    private struct CachedHealthResult {
        let isHealthy: Bool
        let timestamp: Date

        func isValid(for ttl: TimeInterval, at now: Date = Date()) -> Bool {
            return now.timeIntervalSince(timestamp) < ttl
        }
    }

    private let availabilityQueue = DispatchQueue(label: "com.adobe.networkService.availability")
    private var pathProvider: NetworkPathAvailabilityProviding
    private var customHealthCheckProvider: NetworkHealthCheckProviding?
    private var cachedHealthResult: CachedHealthResult?

    public var configuration: NetworkAvailabilityConfiguration {
        didSet {
            availabilityQueue.async {
                self.cachedHealthResult = nil
                self.customHealthCheckProvider = nil
            }
        }
    }

    public init() {
        self.pathProvider = NetworkPathMonitorProvider()
        self.configuration = NetworkAvailabilityConfiguration()
    }

    init(pathProvider: NetworkPathAvailabilityProviding) {
        self.pathProvider = pathProvider
        self.configuration = NetworkAvailabilityConfiguration()
    }

    public func isNetworkAvailable() -> Bool {
        return availabilityQueue.sync {
            guard pathProvider.isPathAvailable() else {
                return false
            }

            guard let healthCheck = configuration.healthCheck else {
                return true
            }

            guard configuration.requireHealthCheckWhenConfigured else {
                return true
            }

            if let cachedHealthResult = cachedHealthResult,
               cachedHealthResult.isValid(for: healthCheck.cacheTTL) {
                return cachedHealthResult.isHealthy
            }

            return false
        }
    }

    public func checkNetworkAvailability(completion: @escaping (NetworkAvailabilityResult) -> Void) {
        availabilityQueue.async {
            guard self.pathProvider.isPathAvailable() else {
                completion(NetworkAvailabilityResult(status: .deviceOffline))
                return
            }

            guard let healthCheck = self.configuration.healthCheck else {
                completion(NetworkAvailabilityResult(status: .pathOnly))
                return
            }

            if let cachedHealthResult = self.cachedHealthResult,
               cachedHealthResult.isValid(for: healthCheck.cacheTTL) {
                let status: NetworkAvailabilityStatus = cachedHealthResult.isHealthy ? .available : .healthCheckFailed
                completion(NetworkAvailabilityResult(status: status))
                return
            }

            let provider = self.resolvedHealthCheckProvider(for: healthCheck)
            provider.performHealthCheck { isHealthy in
                self.availabilityQueue.async {
                    self.cachedHealthResult = CachedHealthResult(isHealthy: isHealthy, timestamp: Date())
                    let status: NetworkAvailabilityStatus = isHealthy ? .available : .healthCheckFailed
                    completion(NetworkAvailabilityResult(status: status))
                }
            }
        }
    }

    public func setPathProvider(_ provider: NetworkPathAvailabilityProviding) {
        availabilityQueue.async {
            self.pathProvider = provider
        }
    }

    public func setHealthCheckProvider(_ provider: NetworkHealthCheckProviding?) {
        availabilityQueue.async {
            self.customHealthCheckProvider = provider
            self.cachedHealthResult = nil
        }
    }

    public func resetToDefaults() {
        availabilityQueue.async {
            self.pathProvider = NetworkPathMonitorProvider()
            self.customHealthCheckProvider = nil
            self.cachedHealthResult = nil
            self.configuration = NetworkAvailabilityConfiguration()
        }
    }

    /// Builds the default HTTP health-check provider using `ServiceProvider.shared.networkService` — the same,
    /// customer-overridable transport used by every other AEP extension — rather than `self` directly. This way,
    /// a customer who overrides `ServiceProvider.shared.networkService` (see: overriding NetworkService) transparently
    /// affects the health check too, instead of it silently escaping through the SDK's own default transport.
    private func resolvedHealthCheckProvider(for healthCheck: NetworkHealthCheckConfiguration) -> NetworkHealthCheckProviding {
        if let customHealthCheckProvider = customHealthCheckProvider {
            return customHealthCheckProvider
        }
        return NetworkHealthCheckProvider(configuration: healthCheck)
    }

    // MARK: - HTTP

    public func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)? = nil) {
        if !networkRequest.url.absoluteString.starts(with: "https") {
            Log.warning(label: LOG_PREFIX, "Network request for (\(networkRequest.url.absoluteString)) could not be created, only https requests are accepted.")
            if let closure = completionHandler {
                closure(HttpConnection(data: nil, response: nil, error: NetworkServiceError.invalidUrl))
            }
            return
        }

        let urlRequest = createURLRequest(networkRequest: networkRequest)
        let urlSession = createURLSession(networkRequest: networkRequest)

        // initiate the network request
        Log.debug(label: LOG_PREFIX, "Initiated (\(networkRequest.httpMethod.toString())) network request to (\(networkRequest.url.absoluteString)).")
        let task = urlSession.dataTask(with: urlRequest, completionHandler: { data, response, error in
            if let closure = completionHandler {
                let httpConnection = HttpConnection(data: data, response: response as? HTTPURLResponse, error: error)
                closure(httpConnection)
            }
        })
        task.resume()
    }

    /// Check if a session is already created for the specified URL, readTimeout, connectTimeout or create a new one with a new `URLSessionConfiguration`
    /// - Parameter networkRequest: current network request
    func createURLSession(networkRequest: NetworkRequest) -> URLSession {
        let sessionId = "\(networkRequest.url.host ?? "")\(networkRequest.readTimeout)\(networkRequest.connectTimeout)"
        return sessionsQueue.sync {
            guard let session = sessions[sessionId] else {
                // Create config for an ephemeral NSURLSession with specified timeouts
                let config = URLSessionConfiguration.ephemeral
                config.urlCache = nil
                config.timeoutIntervalForRequest = networkRequest.readTimeout
                config.timeoutIntervalForResource = networkRequest.connectTimeout

                let newSession: URLSession = URLSession(configuration: config)
                sessions[sessionId] = newSession
                return newSession
            }
            return session
        }
    }

    /// Creates an `URLRequest` with the provided parameters and adds the SDK default headers. The cache policy used is reloadIgnoringLocalCacheData.
    /// - Parameter networkRequest: `NetworkRequest`
    private func createURLRequest(networkRequest: NetworkRequest) -> URLRequest {
        var request = URLRequest(url: networkRequest.url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpMethod = networkRequest.httpMethod.toString()

        if !networkRequest.connectPayload.isEmpty, networkRequest.httpMethod == .post {
            request.httpBody = networkRequest.connectPayload
        }

        for (key, val) in networkRequest.httpHeaders {
            request.setValue(val, forHTTPHeaderField: key)
        }

        return request
    }
}
