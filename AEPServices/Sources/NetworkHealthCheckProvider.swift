/*
 Copyright 2026 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

/// Default HTTP health check provider using `NetworkService`.
public class NetworkHealthCheckProvider: NetworkHealthCheckProviding {
    private let configuration: NetworkHealthCheckConfiguration
    private let networkService: Networking

    public init(configuration: NetworkHealthCheckConfiguration,
                networkService: Networking = ServiceProvider.shared.networkService) {
        self.configuration = configuration
        self.networkService = networkService
    }

    public func performHealthCheck(completion: @escaping (Bool) -> Void) {
        let request = NetworkRequest(url: configuration.endpoint,
                                     httpMethod: .get,
                                     connectTimeout: configuration.timeout,
                                     readTimeout: configuration.timeout)
        networkService.connectAsync(networkRequest: request) { connection in
            let statusCode = connection.response?.statusCode ?? -1
            let isHealthy = connection.error == nil &&
                self.configuration.expectedStatusCodes.contains(statusCode)
            completion(isHealthy)
        }
    }
}
