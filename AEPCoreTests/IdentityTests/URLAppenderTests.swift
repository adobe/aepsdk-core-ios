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
@testable import AEPCore

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
        let configSharedState = [ConfigurationConstants.Keys.EXPERIENCE_CLOUD_ORGID: "testOrg@AdobeOrg", ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        let analyticsSharedState = [IdentityConstants.Analytics.ANALYTICS_ID: "test-aid"]

        // test
        let result = URLAppender.appendVisitorInfo(baseUrl: "", configSharedState: configSharedState, analyticsSharedState: analyticsSharedState, identityProperties: IdentityProperties())

        // verify
        XCTAssertTrue(result.isEmpty)
    }

    func testAppendVisitorInfoForUrlShouldFormatUrlCorrectly() {
        // setup
        let mockUserIdentifier = "test-vid"
        let configSharedState = [ConfigurationConstants.Keys.EXPERIENCE_CLOUD_ORGID: "29849020983@adobeOrg", ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
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
        let configSharedState = [ConfigurationConstants.Keys.EXPERIENCE_CLOUD_ORGID: "29849020983@adobeOrg", ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        let analyticsSharedState = [IdentityConstants.Analytics.ANALYTICS_ID: "test-aid"] as [String : Any]
        var props = IdentityProperties()
        props.mid = MID()
        let expected = "MCMID%3D\(props.mid!.midString)%7CMCAID%3Dtest-aid%7CMCORGID%3D29849020983%40adobeOrg"

        // test
        var result = URLAppender.generateVisitorIdPayload(configSharedState: configSharedState, analyticsSharedState: analyticsSharedState, identityProperties: props)

        // verify that the url starts with Visitor Payload key
        XCTAssertTrue(result.hasPrefix(IdentityConstants.VISITOR_PAYLOAD_KEY))

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
        let configSharedState = [ConfigurationConstants.Keys.EXPERIENCE_CLOUD_ORGID: "29849020983@adobeOrg", ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        let analyticsSharedState = [IdentityConstants.Analytics.ANALYTICS_ID: "test-aid", IdentityConstants.Analytics.VISITOR_IDENTIFIER: ""] as [String : Any]
        var props = IdentityProperties()
        props.mid = MID()
        let expected = "MCMID%3D\(props.mid!.midString)%7CMCAID%3Dtest-aid%7CMCORGID%3D29849020983%40adobeOrg"

        // test
        var result = URLAppender.generateVisitorIdPayload(configSharedState: configSharedState, analyticsSharedState: analyticsSharedState, identityProperties: props)

        // verify that the url starts with Visitor Payload key
        XCTAssertTrue(result.hasPrefix(IdentityConstants.VISITOR_PAYLOAD_KEY))

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
        let configSharedState = [ConfigurationConstants.Keys.EXPERIENCE_CLOUD_ORGID: "29849020983@adobeOrg", ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        let analyticsSharedState = [IdentityConstants.Analytics.ANALYTICS_ID: "test-aid", IdentityConstants.Analytics.VISITOR_IDENTIFIER: mockUserIdentifier] as [String : Any]
        var props = IdentityProperties()
        props.mid = MID()
        let expected = "MCMID%3D\(props.mid!.midString)%7CMCAID%3Dtest-aid%7CMCORGID%3D29849020983%40adobeOrg&adobe_aa_vid=%3F%26%23%26%23%26%23%26%23%3F"

        // test
        var result = URLAppender.generateVisitorIdPayload(configSharedState: configSharedState, analyticsSharedState: analyticsSharedState, identityProperties: props)

        // verify that the url starts with Visitor Payload key
        XCTAssertTrue(result.hasPrefix(IdentityConstants.VISITOR_PAYLOAD_KEY))

        // verify timestamp parameter
        let tsIndex = result.indexOf(char: "=")!
        result = result.substring(from: tsIndex + 1, to: result.count - 1)
        XCTAssertTrue(result.hasPrefix("TS"))

        // chop the TS (timestamp) value part because that's generated using Date and cant be matched.
        let mcmidIndex = result.range(of: "MCMID")
        result = result.substring(from: mcmidIndex?.lowerBound.utf16Offset(in: result) ?? -1, to: result.count - 1)
        XCTAssertEqual(expected, result)
    }

    // MARK: appendParameterToVisitorIdString(...) tests
    
    /// Tests that the key value are properly formatter when the original string is empty
    func testAppendParameterToVisitorIdStringShouldHandleEmpty() {
        // test
        let result = URLAppender.appendParameterToVisitorIdString(original: "", key: "key1", value: "val1")

        // verify
        XCTAssertEqual("key1=val1", result)
    }

    /// Tests that the value is not appended when the key is empty
    func testAppendParameterToVisitorIdStringReturnsOriginalIfKeyIsEmpty() {
        // test
        let result = URLAppender.appendParameterToVisitorIdString(original: "testOriginal", key: "", value: "val1")

        // verify
        XCTAssertEqual("testOriginal", result)
    }

    /// Tests that the key is not appended if the value is empty
    func testAppendParameterToVisitorIdStringReturnsOriginalIfValueIsEmpty() {
        // test
        let result = URLAppender.appendParameterToVisitorIdString(original: "testOriginal", key: "key1", value: "")

        // verify
        XCTAssertEqual("testOriginal", result)
    }

    /// Tests that the key value is properly appended when the original string is not empty
    func testAppendParameterToVisitorIdStringHappy() {
        // test
        let result = URLAppender.appendParameterToVisitorIdString(original: "hello=world", key: "key1", value: "val1")

        // verify
        XCTAssertEqual("hello=world|key1=val1", result)
    }
}
