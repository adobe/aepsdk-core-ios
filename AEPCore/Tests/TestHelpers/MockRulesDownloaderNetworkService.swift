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

enum MockRulesDownloaderResponses {
    case success
    case error
    case notModified
}

struct MockRulesDownloaderNetworkService: Networking {
    var response: MockRulesDownloaderResponses!

    let expectedData = try? Data(contentsOf: RulesDownloaderTests.rulesUrl!)

    let validResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
    let invalidResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)
    let notModifiedResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 304, httpVersion: nil, headerFields: nil)
    func connectAsync(networkRequest _: NetworkRequest, completionHandler: ((HttpConnection) -> Void)?) {
        switch response {
        case .success:
            let httpConnection = HttpConnection(data: expectedData, response: validResponse, error: nil)
            completionHandler!(httpConnection)
        case .error:
            let httpConnection = HttpConnection(data: nil, response: invalidResponse, error: NetworkServiceError.invalidUrl)
            completionHandler!(httpConnection)
        case .notModified:
            let httpConnection = HttpConnection(data: nil, response: notModifiedResponse, error: nil)
            completionHandler!(httpConnection)
        case .none:
            print("Invalid response type")
        }
    }
}
