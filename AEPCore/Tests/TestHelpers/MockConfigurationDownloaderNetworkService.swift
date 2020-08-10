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

@testable import AEPCore
import AEPServices
import Foundation

enum MockConfigurationDownloaderResponses {
    case success
    case error
    case notModified
}

struct MockConfigurationDownloaderNetworkService: Networking {
    let validResponseDictSize = 16
    let responseType: MockConfigurationDownloaderResponses!
    let expectedData = """
    {
      "target.timeout": 5,
      "global.privacy": "optedin",
      "analytics.backdatePreviousSessionInfo": false,
      "analytics.offlineEnabled": true,
      "build.environment": "prod",
      "rules.url": "https://assets.adobedtm.com/launch-EN1a68f9bc5b3c475b8c232adc3f8011fb-rules.zip",
      "target.clientCode": "",
      "experienceCloud.org": "972C898555E9F7BC7F000101@AdobeOrg",
      "lifecycle.sessionTimeout": 300,
      "target.environmentId": "",
      "analytics.server": "obumobile5.sc.omtrdc.net",
      "analytics.rsids": "mobile5adobe.store.sprint.demo",
      "analytics.batchLimit": 3,
      "property.id": "PR3dd64c475eb747339f0319676d56b1df",
      "global.ssl": true,
      "analytics.aamForwardingEnabled": true
    }
    """.data(using: .utf8)

    let expectedValidHttpUrlResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: [:])
    let expectedInValidHttpUrlResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 500, httpVersion: nil, headerFields: [:])
    let expectedNotModifiedHttpUrlResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 304, httpVersion: nil, headerFields: [:])

    func connectAsync(networkRequest _: NetworkRequest, completionHandler: ((HttpConnection) -> Void)?) {
        switch responseType {
        case .success:
            let httpConnection = HttpConnection(data: expectedData, response: expectedValidHttpUrlResponse, error: nil)
            completionHandler!(httpConnection)
        case .error:
            let httpConnection = HttpConnection(data: nil, response: expectedInValidHttpUrlResponse, error: NetworkServiceError.invalidUrl)
            completionHandler!(httpConnection)
        case .notModified:
            let httpConnection = HttpConnection(data: nil, response: expectedNotModifiedHttpUrlResponse, error: nil)
            completionHandler!(httpConnection)
        case .none:
            print("invalid response type")
        }
    }
}
