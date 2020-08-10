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

import AEPServices
import Foundation

public class MockNetworkServiceOverrider: Networking {
    public var connectAsyncCalled: Bool = false
    public var connectAsyncCalledWithNetworkRequest: NetworkRequest?
    public var connectAsyncCalledWithCompletionHandler: ((HttpConnection) -> Void)?
    public var expectedResponse: HttpConnection?

    public init() {}

    public func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)? = nil) {
        print("Do nothing \(networkRequest)")
        connectAsyncCalled = true
        connectAsyncCalledWithNetworkRequest = networkRequest
        connectAsyncCalledWithCompletionHandler = completionHandler
        if let expectedResponse = expectedResponse, let completionHandler = completionHandler {
            completionHandler(expectedResponse)
        }
    }

    public func reset() {
        connectAsyncCalled = false
        connectAsyncCalledWithNetworkRequest = nil
        connectAsyncCalledWithCompletionHandler = nil
    }
}
