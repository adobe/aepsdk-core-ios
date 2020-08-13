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

/// The HttpConnection represents the response to NetworkRequest, to be used for network completion handlers and when overriding the network stack in place of internal network connection implementation.
public struct HttpConnection {
    /// Returns application server response data from the connection or nil if there was an error
    public let data: Data?

    /// Response metadata provided by the server
    public let response: HTTPURLResponse?

    /// The error associated with the request failure or nil on success
    public let error: Error?

    /// Initialize an HttpConnection structure
    ///
    /// - Parameters:
    ///   - data: optional data returned from the server in the connection
    ///   - response: the response from the server
    ///   - error: an optional error if something failed
    public init(data: Data?, response: HTTPURLResponse?, error: Error?) {
        self.data = data
        self.response = response
        self.error = error
    }
}

public extension HttpConnection {
    /// Returns application server response data from the connection as string, if available.
    var responseString: String? {
        if let unwrappedData = data {
            return String(data: unwrappedData, encoding: .utf8)
        }

        return nil
    }

    /// Returns the connection response code for the connection request.
    var responseCode: Int? {
        return response?.statusCode
    }

    /// Returns application server response message as string extracted from the `response` property, if available.
    var responseMessage: String? {
        if let code = responseCode {
            return HTTPURLResponse.localizedString(forStatusCode: code)
        }

        return nil
    }

    /// Returns a value for the response header key from the `response` property, if available.
    /// This is protocol specific. For example, HTTP URLs could have headers like "last-modified", or "ETag" set.
    /// - Parameter forKey: the header key name sent in response when requesting a connection to the URL.
    func responseHttpHeader(forKey: String) -> String? {
        return response?.allHeaderFields[forKey] as? String
    }
}
