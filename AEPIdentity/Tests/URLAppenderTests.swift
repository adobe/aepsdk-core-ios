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

import XCTest
@testable import AEPIdentity
import AEPCore

private extension String {

    /// Returns the first index of the character in this `String`
    /// - Parameter char: character to be indexed
    /// - Returns: The index of `char` in this `String`, otherwise nil
    func indexOf(char: Character) -> Int? {
        return firstIndex(of: char)?.utf16Offset(in: self)
    }

    func substring(from: Int, to: Int) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: from)
        let endIndex = self.index(self.startIndex, offsetBy: to)
        return String(self[startIndex...endIndex])
     }
}

class URLAppenderTests: XCTestCase {
    // MARK: appendVisitorInfo(...) tests
    
    /// When base url is empty the result should be empty
    func testAppendVisitorInfoEmptyBaseUrl() {
        // setup
        let configSharedState = [IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "testOrg@AdobeOrg", IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        let analyticsSharedState = [IdentityConstants.Analytics.ANALYTICS_ID: "test-aid"]

        // test
        let result = URLAppender.appendVisitorInfo(baseUrl: "", configSharedState: configSharedState, analyticsSharedState: analyticsSharedState, identityProperties: IdentityProperties())

        // verify
        XCTAssertTrue(result.isEmpty)
    }

    func testAppendVisitorInfoForUrlShouldFormatUrlCorrectly() {
        // setup
        let mockUserIdentifier = "test-vid"
        let configSharedState = [IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "29849020983@adobeOrg", IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        let analyticsSharedState = [IdentityConstants.Analytics.ANALYTICS_ID: "test-aid", IdentityConstants.Analytics.VISITOR_IDENTIFIER: mockUserIdentifier]
        var props = IdentityProperties()
        props.mid = MID()
        let expected = "MCMID%3D\(props.mid!.midString)%7CMCAID%3Dtest-aid%7CMCORGID%3D29849020983%40adobeOrg&adobe_aa_vid=\(mockUserIdentifier)"

        let baseUrl = "test-base-url.com/"

        // test
        var result = URLAppender.appendVisitorInfo(baseUrl: baseUrl, configSharedState: configSharedState, analyticsSharedState: analyticsSharedState, identityProperties: props)

        // verify that the url starts with Visitor Payload key
        XCTAssertTrue(result.hasPrefix(baseUrl))

        // verify timestamp parameter
        let tsIndex = result.indexOf(char: "=")!
        result = result.substring(from: tsIndex + 1, to: result.count - 1)
        XCTAssertTrue(result.hasPrefix("TS"))

        // chop the TS (timestamp) value part because that's generated using Date and cant be matched.
        let mcmidIndex = result.range(of: "MCMID")
        result = result.substring(from: mcmidIndex?.lowerBound.utf16Offset(in: result) ?? -1, to: result.count - 1)
        XCTAssertEqual(expected, result)
    }

    // MARK: generateVisitorIdPayload(...) tests
    
    /// Tests that when the vid is not provided that we do not append the url parameter for the vid
    func testGenerateVisitorIdPayloadNoVid() {
        // setup
        let configSharedState = [IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "29849020983@adobeOrg", IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        let analyticsSharedState = [IdentityConstants.Analytics.ANALYTICS_ID: "test-aid"] as [String : Any]
        var props = IdentityProperties()
        props.mid = MID()
        let expected = "MCMID%3D\(props.mid!.midString)%7CMCAID%3Dtest-aid%7CMCORGID%3D29849020983%40adobeOrg"

        // test
        var result = URLAppender.generateVisitorIdPayload(configSharedState: configSharedState, analyticsSharedState: analyticsSharedState, identityProperties: props)

        // verify that the url starts with Visitor Payload key
        XCTAssertTrue(result.hasPrefix(IdentityConstants.URLKeys.VISITOR_PAYLOAD_KEY))

        // verify timestamp parameter
        let tsIndex = result.indexOf(char: "=")!
        result = result.substring(from: tsIndex + 1, to: result.count - 1)
        XCTAssertTrue(result.hasPrefix("TS"))

        // chop the TS (timestamp) value part because that's generated using Date and cant be matched.
        let mcmidIndex = result.range(of: "MCMID")
        result = result.substring(from: mcmidIndex?.lowerBound.utf16Offset(in: result) ?? -1, to: result.count - 1)
        XCTAssertEqual(expected, result)
    }

    /// Tests that when the vid is empty that we do not append the url parameter for the vid
    func testGenerateVisitorIdPayloadEmptyVid() {
        // setup
        let configSharedState = [IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "29849020983@adobeOrg", IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        let analyticsSharedState = [IdentityConstants.Analytics.ANALYTICS_ID: "test-aid", IdentityConstants.Analytics.VISITOR_IDENTIFIER: ""] as [String : Any]
        var props = IdentityProperties()
        props.mid = MID()
        let expected = "MCMID%3D\(props.mid!.midString)%7CMCAID%3Dtest-aid%7CMCORGID%3D29849020983%40adobeOrg"

        // test
        var result = URLAppender.generateVisitorIdPayload(configSharedState: configSharedState, analyticsSharedState: analyticsSharedState, identityProperties: props)

        // verify that the url starts with Visitor Payload key
        XCTAssertTrue(result.hasPrefix(IdentityConstants.URLKeys.VISITOR_PAYLOAD_KEY))

        // verify timestamp parameter
        let tsIndex = result.indexOf(char: "=")!
        result = result.substring(from: tsIndex + 1, to: result.count - 1)
        XCTAssertTrue(result.hasPrefix("TS"))

        // chop the TS (timestamp) value part because that's generated using Date and cant be matched.
        let mcmidIndex = result.range(of: "MCMID")
        result = result.substring(from: mcmidIndex?.lowerBound.utf16Offset(in: result) ?? -1, to: result.count - 1)
        XCTAssertEqual(expected, result)
    }

    /// Tests that the VID is properly encoded into the visitor id payload
    func testGenerateVisitorIdPayloadEncodedVID() {
        // setup
        let mockUserIdentifier = "?&#&#&#&#?"
        let configSharedState = [IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "29849020983@adobeOrg", IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        let analyticsSharedState = [IdentityConstants.Analytics.ANALYTICS_ID: "test-aid", IdentityConstants.Analytics.VISITOR_IDENTIFIER: mockUserIdentifier] as [String : Any]
        var props = IdentityProperties()
        props.mid = MID()
        let expected = "MCMID%3D\(props.mid!.midString)%7CMCAID%3Dtest-aid%7CMCORGID%3D29849020983%40adobeOrg&adobe_aa_vid=%3F%26%23%26%23%26%23%26%23%3F"

        // test
        var result = URLAppender.generateVisitorIdPayload(configSharedState: configSharedState, analyticsSharedState: analyticsSharedState, identityProperties: props)

        // verify that the url starts with Visitor Payload key
        XCTAssertTrue(result.hasPrefix(IdentityConstants.URLKeys.VISITOR_PAYLOAD_KEY))

        // verify timestamp parameter
        let tsIndex = result.indexOf(char: "=")!
        result = result.substring(from: tsIndex + 1, to: result.count - 1)
        XCTAssertTrue(result.hasPrefix("TS"))

        // chop the TS (timestamp) value part because that's generated using Date and cant be matched.
        let mcmidIndex = result.range(of: "MCMID")
        result = result.substring(from: mcmidIndex?.lowerBound.utf16Offset(in: result) ?? -1, to: result.count - 1)
        XCTAssertEqual(expected, result)
    }
    
}
