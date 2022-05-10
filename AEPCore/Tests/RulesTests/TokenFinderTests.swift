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
import AEPCoreMocks
import XCTest

class TokenFinderTests: XCTestCase {
    func testGetTokenValue_event_type_source() {
        /// Given: initialize `TokenFinder` with mocked extension runtime & dummy event
        let runtime = TestableExtensionRuntime()
        let tokenFinder = TokenFinder(event: Event(name: "eventName", type: "eventType", source: "eventSource", data: nil), extensionRuntime: runtime)
        /// When: retrieve token `~type` and `~source`
        guard let type = tokenFinder.get(key: "~type") as? String, let source = tokenFinder.get(key: "~source") as? String else {
            XCTFail("Expected no-nil event type and event source")
            return
        }
        /// Then
        XCTAssertEqual("eventType", type)
        XCTAssertEqual("eventSource", source)
    }

    func testGetTokenValue_sdk_version() {
        /// Given: initialize `TokenFinder` with mocked extension runtime & dummy event
        let runtime = TestableExtensionRuntime()
        let tokenFinder = TokenFinder(event: Event(name: "eventName", type: "eventType", source: "eventSource", data: nil), extensionRuntime: runtime)
        /// When: retrieve token `~sdkver`
        guard let version = tokenFinder.get(key: "~sdkver") as? String else {
            XCTFail("Expected no-nil SDK version")
            return
        }
        /// Then:  return `String` value & same as `MobileCore.extensionVersion`
        XCTAssertEqual(MobileCore.extensionVersion, version)
    }

    func testGetTokenValue_cachebust() {
        /// Given: initialize `TokenFinder` with mocked extension runtime & dummy event
        let runtime = TestableExtensionRuntime()
        let tokenFinder = TokenFinder(event: Event(name: "eventName", type: "eventType", source: "eventSource", data: nil), extensionRuntime: runtime)
        /// When: retrieve token `~cachebust`
        guard let randomString = tokenFinder.get(key: "~cachebust") as? String, let randomInt = Int(randomString) else {
            XCTFail("Expected no-nil random int")
            return
        }
        /// Then:  return `Int` value less then  100000000
        XCTAssertTrue(randomInt < 100_000_000)
    }

    func testGetTokenValue_url() {
        /// Given: initialize `TokenFinder` with mocked extension runtime & dummy event which should contain non-nil event data and it's data value should contain `String` and `Double`
        let runtime = TestableExtensionRuntime()
        let tokenFinder = TokenFinder(event: Event(name: "eventName", type: "eventType", source: "eventSource", data: ["key1": "value1", "key2": ["key22": 22.0]]), extensionRuntime: runtime)
        /// When: retrieve token `~all_url`
        guard let urlQueryString = tokenFinder.get(key: "~all_url") as? String else {
            XCTFail("Expected no-nil url query string")
            return
        }
        /// Then
        XCTAssertTrue(urlQueryString == "key1=value1&key2.key22=22.0" || urlQueryString == "key2.key22=22.0&key1=value1")
    }

    func testGetTokenValue_url_empty_kvp() {
        /// Given: initialize `TokenFinder` with mocked extension runtime & dummy event whose event data property is `nil`
        let runtime = TestableExtensionRuntime()
        let tokenFinder = TokenFinder(event: Event(name: "eventName", type: "eventType", source: "eventSource", data: nil), extensionRuntime: runtime)
        /// When: retrieve token `~all_url`
        guard let urlQueryString = tokenFinder.get(key: "~all_url") as? String else {
            XCTFail("Expected no-nil url query string")
            return
        }
        /// Then: return empty `String`
        XCTAssertEqual("", urlQueryString)
    }

    func testGetTokenValue_json() {
        /// Given: initialize `TokenFinder` with mocked extension runtime & dummy event which should contain non-nil event data and it's data value should contain `String` and `Double`
        let runtime = TestableExtensionRuntime()
        let tokenFinder = TokenFinder(event: Event(name: "eventName", type: "eventType", source: "eventSource", data: ["key1": "value1", "key2": ["key22": 22.0]]), extensionRuntime: runtime)
        /// When: retrieve token `~all_json`
        guard let json = tokenFinder.get(key: "~all_json") as? String else {
            XCTFail("Expected no-nil json string")
            return
        }
        /// Then
        XCTAssertEqual(json, #"{"key1":"value1","key2":{"key22":22}}"#)
    }

    func testGetTokenValue_json_empty_kvp() {
        /// Given: initialize `TokenFinder` with mocked extension runtime & dummy event whose event data property is `nil`
        let runtime = TestableExtensionRuntime()
        let tokenFinder = TokenFinder(event: Event(name: "eventName", type: "eventType", source: "eventSource", data: nil), extensionRuntime: runtime)
        /// When: retrieve token `~all_json`
        guard let json = tokenFinder.get(key: "~all_json") as? String else {
            XCTFail("Expected no-nil json string")
            return
        }
        /// Then: return empty `String`
        XCTAssertEqual(json, "")
    }

    func testGetTokenValue_timestamp() {
        /// Given: initialize `TokenFinder` with mocked extension runtime & dummy event
        let runtime = TestableExtensionRuntime()
        let tokenFinder = TokenFinder(event: Event(name: "eventName", type: "eventType", source: "eventSource", data: nil), extensionRuntime: runtime)
        let formatter_ISO8601 = DateFormatter()
        formatter_ISO8601.timeZone = TimeZone.init(abbreviation: "UTC")
        formatter_ISO8601.locale = Locale(identifier: "en_US_POSIX")
        formatter_ISO8601.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        let formatter_ISO8601NoColon = DateFormatter()
        formatter_ISO8601NoColon.locale = Locale(identifier: "en_US_POSIX")
        formatter_ISO8601NoColon.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"

        /// When: retrieve token `~timestampz`, `~timestampp` & `~timestampu`
        guard let date_ISO8601_string = tokenFinder.get(key: "~timestampp") as? String, let date_ISO8601 = formatter_ISO8601.date(from: date_ISO8601_string), let date_ISO8601NoColon_string = tokenFinder.get(key: "~timestampz") as? String, let date_ISO8601NoColon = formatter_ISO8601NoColon.date(from: date_ISO8601NoColon_string), let date_UNIX_Int = tokenFinder.get(key: "~timestampu") as? Int else {
            XCTFail("Expected no-nil timestamp")
            return
        }
        let date_UNIX = Date(timeIntervalSince1970: TimeInterval(date_UNIX_Int))
        // Then: return same timestamp with different format, but only compare seconds as ISO8601NoColon and UNIX do not count milliseconds
        XCTAssertEqual(0, Calendar.current.dateComponents([.second], from: date_ISO8601, to: date_ISO8601NoColon).second)
        XCTAssertEqual(0, Calendar.current.dateComponents([.second], from: date_ISO8601, to: date_UNIX).second)
    }

    func testGetTokenValue_shared_state() {
        /// Given: initialize `TokenFinder` with mocked  dummy event & extension runtime which contains a valid shared state
        let runtime = TestableExtensionRuntime()
        runtime.mockedSharedStates["com.adobe.module.lifecycle"] = SharedStateResult(status: .set, value: ["lifecyclecontextdata": ["dayssincelastupgrade": 10]])
        let tokenFinder = TokenFinder(event: Event(name: "eventName", type: "eventType", source: "eventSource", data: nil), extensionRuntime: runtime)
        /// When: retrieve token `~state.com.adobe.module.lifecycle/lifecyclecontextdata.dayssincelastupgrade`
        guard let days = tokenFinder.get(key: "~state.com.adobe.module.lifecycle/lifecyclecontextdata.dayssincelastupgrade") as? Int else {
            XCTFail("Expected no-nil shared state")
            return
        }
        /// Then: return shared state value with right data `Type`
        XCTAssertEqual(10, days)
    }

    func testGetTokenValue_shared_state_extension_name_not_exist() {
        /// Given: initialize `TokenFinder` with mocked  dummy event & extension runtime which don't have the right extension registered
        let runtime = TestableExtensionRuntime()
        let tokenFinder = TokenFinder(event: Event(name: "eventName", type: "eventType", source: "eventSource", data: nil), extensionRuntime: runtime)
        /// When: retrieve token `~state.com.adobe.module.lifecycle/lifecyclecontextdata.dayssincelastupgrade`
        guard tokenFinder.get(key: "~state.com.adobe.module.lifecycle/lifecyclecontextdata.dayssincelastupgrade") != nil else {
            /// Then: return `nil`
            return
        }
        XCTFail("Expected nil return")
    }

    func testGetTokenValue_shared_state_not_exist() {
        /// Given: initialize `TokenFinder` with mocked  dummy event & extension runtime which don't contain the right key
        let runtime = TestableExtensionRuntime()
        runtime.mockedSharedStates["com.adobe.module.lifecycle"] = SharedStateResult(status: .set, value: ["lifecyclecontextdata": ["a": 10]])
        let tokenFinder = TokenFinder(event: Event(name: "eventName", type: "eventType", source: "eventSource", data: nil), extensionRuntime: runtime)
        /// When: retrieve token `~state.com.adobe.module.lifecycle/lifecyclecontextdata.dayssincelastupgrade`
        guard tokenFinder.get(key: "~state.com.adobe.module.lifecycle/lifecyclecontextdata.dayssincelastupgrade") != nil else {
            /// Then: return `nil`
            return
        }
        XCTFail("Expected nil return")
    }
}
