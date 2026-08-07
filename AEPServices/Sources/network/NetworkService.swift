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

class NetworkService: Networking {
    private let LOG_PREFIX = "NetworkService"

    private var sessionsQueue = DispatchQueue(label: "com.adobe.networkService.sessions")
    private var sessions: [String: URLSession] = [:]

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
