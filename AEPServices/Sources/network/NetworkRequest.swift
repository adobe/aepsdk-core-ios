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

/// NetworkRequest struct to be used by the NetworkService and the HttpConnectionPerformer when initiating network calls
@objc(AEPNetworkRequest) public class NetworkRequest: NSObject {

    private static let REQUEST_HEADER_KEY_USER_AGENT = "User-Agent"

    public let url: URL
    public let httpMethod: HttpMethod
    public let connectPayload: Data
    public let httpHeaders: [String: String]
    public let connectTimeout: TimeInterval
    public let readTimeout: TimeInterval

    /// Initialize the `NetworkRequest`
    /// - Parameters:
    ///   - url: URL used to initiate the network connection, should use https scheme
    ///   - httpMethod: `HttpMethod` to be used for this network request; the default value is GET
    ///   - connectPayload: the body of the network request as a String; this parameter is ignored for GET requests
    ///   - httpHeaders: optional HTTP headers for the request
    ///   - connectTimeout: optional connect timeout value in seconds; default is 5 seconds
    ///   - readTimeout: optional read timeout value in seconds, used to wait for a read to finish after a successful connect, default is 5 seconds
    /// - Returns: an initialized `NetworkRequest` object
    public convenience init(url: URL, httpMethod: HttpMethod = HttpMethod.get, connectPayload: String = "", httpHeaders: [String: String] = [:], connectTimeout: TimeInterval = 5, readTimeout: TimeInterval = 5) {
        self.init(url: url,
                  httpMethod: httpMethod,
                  connectPayloadData: connectPayload.data(using: .utf8) ?? Data(),
                  httpHeaders: httpHeaders,
                  connectTimeout: connectTimeout,
                  readTimeout: readTimeout)
    }

    /// Initialize the `NetworkRequest`
    /// - Parameters:
    ///   - url: URL used to initiate the network connection, should use https scheme
    ///   - connectPayloadData: the body of the network request as a Data
    ///   - httpHeaders: optional HTTP headers for the request
    ///   - connectTimeout: optional connect timeout value in seconds; default is 5 seconds
    ///   - readTimeout: optional read timeout value in seconds, used to wait for a read to finish after a successful connect, default is 5 seconds
    /// - Returns: an initialized `NetworkRequest` object
    public init(url: URL, httpMethod: HttpMethod = HttpMethod.get, connectPayloadData: Data, httpHeaders: [String: String] = [:], connectTimeout: TimeInterval = 5, readTimeout: TimeInterval = 5) {
        self.url = url
        self.httpMethod = httpMethod
        self.connectPayload = connectPayloadData

        let systemInfoService = ServiceProvider.shared.systemInfoService
        let defaultHeaders = [NetworkRequest.REQUEST_HEADER_KEY_USER_AGENT: systemInfoService.getDefaultUserAgent(),
                              HttpConnectionConstants.Header.HTTP_HEADER_KEY_ACCEPT_LANGUAGE: DefaultHeadersFormatter.formatLocale(systemInfoService.getSystemLocaleName())]
        self.httpHeaders = defaultHeaders.merging(httpHeaders) { _, new in new } // add in default headers and apply `httpHeaders` on top

        self.connectTimeout = connectTimeout
        self.readTimeout = readTimeout
    }
}
