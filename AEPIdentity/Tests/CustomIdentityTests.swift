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
@testable import AEPServicesMocks

class CustomIdentityTests: XCTestCase {

    // MARK: Codable tests
    
    func testCustomIdentityEmptyString_DecodingReturnsNil() {
        // setup
        let customIdentityJson = ""
        
        // test decoding
        let decodedCustomId = try? JSONDecoder().decode(CustomIdentity.self, from: customIdentityJson.data(using: .utf8)!)
        
        // verify decoding
        XCTAssertNil(decodedCustomId)
    }
    
    func testCustomIdentityEmptyJson_DecodingReturnsNil() {
        // setup
        let customIdentityJson = """
        {
        }
        """
        
        // test decoding
        let decodedCustomId = try? JSONDecoder().decode(CustomIdentity.self, from: customIdentityJson.data(using: .utf8)!)
        
        // verify decoding
        XCTAssertNil(decodedCustomId)
    }
    
    func testCustomIdentityInvalidJson_DecodingReturnsNil() {
        // setup
        let customIdentityJson = """
        {
           "not-a-real-key": "some-value"
        }
        """
        
        // test decoding
        let decodedCustomId = try? JSONDecoder().decode(CustomIdentity.self, from: customIdentityJson.data(using: .utf8)!)
        
        // verify decoding
        XCTAssertNil(decodedCustomId)
    }
    
    func testCustomIdentityAllProperties_EncodesAndDecodesWithExtraneousKey() {
        // setup
        let customIdentityJson = """
        {
          "id_type" : "test-type",
          "id" : "test-id",
          "id_origin" : "test-origin",
          "authentication_state" : 1,
          "not-a-real-key": "some-value"
        }
        """
        
        let expectedCustomIdentityJson = """
        {
          "id_type" : "test-type",
          "id" : "test-id",
          "id_origin" : "test-origin",
          "authentication_state" : 1
        }
        """
        
        // test decoding
        let decodedCustomId = try! JSONDecoder().decode(CustomIdentity.self, from: customIdentityJson.data(using: .utf8)!)
        
        // verify decoding
        XCTAssertEqual("test-type", decodedCustomId.type)
        XCTAssertEqual("test-id", decodedCustomId.identifier)
        XCTAssertEqual("test-origin", decodedCustomId.origin)
        XCTAssertEqual(MobileVisitorAuthenticationState.authenticated, decodedCustomId.authenticationState)
        
        // test encoding
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let encoded = try! encoder.encode(decodedCustomId)
        
        // verify encoding
        XCTAssertEqual(expectedCustomIdentityJson, String(data: encoded, encoding: .utf8))
    }
    
    func testCustomIdentityAllProperties_EncodesAndDecodes() {
        // setup
        let customIdentityJson = """
        {
          "id_type" : "test-type",
          "id" : "test-id",
          "id_origin" : "test-origin",
          "authentication_state" : 1
        }
        """
        
        // test decoding
        let decodedCustomId = try! JSONDecoder().decode(CustomIdentity.self, from: customIdentityJson.data(using: .utf8)!)
        
        // verify decoding
        XCTAssertEqual("test-type", decodedCustomId.type)
        XCTAssertEqual("test-id", decodedCustomId.identifier)
        XCTAssertEqual("test-origin", decodedCustomId.origin)
        XCTAssertEqual(MobileVisitorAuthenticationState.authenticated, decodedCustomId.authenticationState)
        
        // test encoding
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let encoded = try! encoder.encode(decodedCustomId)
        
        // verify encoding
        XCTAssertEqual(customIdentityJson, String(data: encoded, encoding: .utf8))
    }
    
    func testCustomIdentityMissingType_EncodesAndDecodes() {
        // setup
        let customIdentityJson = """
        {
          "id" : "test-id",
          "authentication_state" : 1,
          "id_origin" : "test-origin"
        }
        """
        
        // test decoding
        let decodedCustomId = try! JSONDecoder().decode(CustomIdentity.self, from: customIdentityJson.data(using: .utf8)!)
        
        // verify decoding
        XCTAssertNil(decodedCustomId.type)
        XCTAssertEqual("test-id", decodedCustomId.identifier)
        XCTAssertEqual("test-origin", decodedCustomId.origin)
        XCTAssertEqual(MobileVisitorAuthenticationState.authenticated, decodedCustomId.authenticationState)
        
        // test encoding
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let encoded = try! encoder.encode(decodedCustomId)
        
        // verify encoding
        XCTAssertEqual(customIdentityJson, String(data: encoded, encoding: .utf8))
    }
    
    func testCustomIdentityMissingId_EncodesAndDecodes() {
        // setup
        let customIdentityJson = """
        {
          "id_type" : "test-type",
          "authentication_state" : 1,
          "id_origin" : "test-origin"
        }
        """
        
        // test decoding
        let decodedCustomId = try! JSONDecoder().decode(CustomIdentity.self, from: customIdentityJson.data(using: .utf8)!)
        
        // verify decoding
        XCTAssertEqual("test-type", decodedCustomId.type)
        XCTAssertNil(decodedCustomId.identifier)
        XCTAssertEqual("test-origin", decodedCustomId.origin)
        XCTAssertEqual(MobileVisitorAuthenticationState.authenticated, decodedCustomId.authenticationState)
        
        // test encoding
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let encoded = try! encoder.encode(decodedCustomId)
        
        // verify encoding
        XCTAssertEqual(customIdentityJson, String(data: encoded, encoding: .utf8))
    }
    
    func testCustomIdentityMissingOrigin_EncodesAndDecodes() {
        // setup
        let customIdentityJson = """
        {
          "id_type" : "test-type",
          "id" : "test-id",
          "authentication_state" : 1
        }
        """
        
        // test decoding
        let decodedCustomId = try! JSONDecoder().decode(CustomIdentity.self, from: customIdentityJson.data(using: .utf8)!)
        
        // verify decoding
        XCTAssertEqual("test-type", decodedCustomId.type)
        XCTAssertEqual("test-id", decodedCustomId.identifier)
        XCTAssertNil(decodedCustomId.origin)
        XCTAssertEqual(MobileVisitorAuthenticationState.authenticated, decodedCustomId.authenticationState)
        
        // test encoding
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let encoded = try! encoder.encode(decodedCustomId)
        
        // verify encoding
        XCTAssertEqual(customIdentityJson, String(data: encoded, encoding: .utf8))
    }
    
    // MARK: Equatable tests
    
    /// CustomIdentity's with same types are considered equal
    func testCustomIdentityAreEqual() {
        // setup
        let id1 = CustomIdentity(origin: "origin", type: "type", identifier: "id", authenticationState: .authenticated)
        let id2 = CustomIdentity(origin: "origin1", type: "type", identifier: "id1", authenticationState: .loggedOut)

        // test & verify
        XCTAssertTrue(id1 == id2)
    }

    /// CustomIdentity's with different types are considered not equal
    func testCustomIdentityAreNotEqual() {
        // setup
        let id1 = CustomIdentity(origin: "origin", type: "type", identifier: "id", authenticationState: .authenticated)
        let id2 = CustomIdentity(origin: "origin", type: "type1", identifier: "id", authenticationState: .authenticated)

        // test & verify
        XCTAssertFalse(id1 == id2)
    }
    
    // MARK: init(dict:) tests
    
    func testCustomIdentity_initFromDictionary() {
        let dict: [String: Any] = [
            "id_type": "test-type",
            "id_origin": "test-origin",
            "id": "test-id",
            "authentication_state": 1
        ]

        let customId = CustomIdentity(dict: dict)
        XCTAssertEqual("test-id", customId.identifier)
        XCTAssertEqual("test-type", customId.type)
        XCTAssertEqual(MobileVisitorAuthenticationState.authenticated, customId.authenticationState)
        XCTAssertEqual("test-origin", customId.origin)
    }

    func testCustomIdentity_initFromDictionary_setStateToUnknown_whenInvalid() {
        let dict: [String: Any] = [
            "id_type": "test-type",
            "id_origin": "test-origin",
            "id": "test-id",
            "authentication_state": 11
        ]

        let customId = CustomIdentity(dict: dict)
        XCTAssertEqual("test-id", customId.identifier)
        XCTAssertEqual("test-type", customId.type)
        XCTAssertEqual(MobileVisitorAuthenticationState.unknown, customId.authenticationState)
        XCTAssertEqual("test-origin", customId.origin)
    }
    
    func testCustomIdentity_initFromDictionary_setStateToUnknown_whenEmpty() {
        let dict: [String: Any] = [
            "id_type": "test-type",
            "id_origin": "test-origin",
            "id": "test-id"
        ]

        let customId = CustomIdentity(dict: dict)
        XCTAssertEqual("test-id", customId.identifier)
        XCTAssertEqual("test-type", customId.type)
        XCTAssertEqual(MobileVisitorAuthenticationState.unknown, customId.authenticationState)
        XCTAssertEqual("test-origin", customId.origin)
    }
    
    func testCustomIdentity_initFromDictionary_invalidId_returnsNilId() {
        let dict: [String: Any] = [
            "id_type": "test-type",
            "id_origin": "test-origin",
            "id": -1, // expected type String
            "authentication_state": 1
        ]

        let customId = CustomIdentity(dict: dict)
        XCTAssertNil(customId.identifier)
        XCTAssertEqual("test-type", customId.type)
        XCTAssertEqual(MobileVisitorAuthenticationState.authenticated, customId.authenticationState)
        XCTAssertEqual("test-origin", customId.origin)
    }

    func testCustomIdentity_initFromDictionary_invalidType_returnsNilType() {
        let dict: [String: Any] = [
            "id_type": -1, // expected type String
            "id_origin": "test-origin",
            "id": "test-id",
            "authentication_state": 1
        ]

        let customId = CustomIdentity(dict: dict)
        XCTAssertEqual("test-id", customId.identifier)
        XCTAssertNil(customId.type)
        XCTAssertEqual(MobileVisitorAuthenticationState.authenticated, customId.authenticationState)
        XCTAssertEqual("test-origin", customId.origin)
    }
    
    func testCustomIdentity_initFromDictionary_invalidOrigin_returnsNilOrigin() {
        let dict: [String: Any] = [
            "id_type": "test-type",
            "id_origin": -1, // expected type String
            "id": "test-id",
            "authentication_state": 1
        ]

        let customId = CustomIdentity(dict: dict)
        XCTAssertEqual("test-id", customId.identifier)
        XCTAssertEqual("test-type", customId.type)
        XCTAssertEqual(MobileVisitorAuthenticationState.authenticated, customId.authenticationState)
        XCTAssertNil(customId.origin)
    }

}
