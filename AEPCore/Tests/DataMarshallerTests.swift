/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation
import XCTest

@testable import AEPCore


class DataMarshallerTests: XCTestCase {
    
    func test_marshalLaunchInfo_deeplink(){
        let dictionary = DataMarshaller.marshalLaunchInfo(["adb_deeplink":"abc://myawesomeapp?some=param&some=other_param"])
        XCTAssertEqual(1, dictionary.count)
        XCTAssertEqual("abc://myawesomeapp?some=param&some=other_param", dictionary["deeplink"] as? String)
    }
    
    func test_marshalLaunchInfo_deeplink_empty_value(){
        let dictionary = DataMarshaller.marshalLaunchInfo(["adb_deeplink":""])
        XCTAssertEqual(0, dictionary.count)
    }
    
    func test_marshalLaunchInfo_PushNotification(){
        let dictionary = DataMarshaller.marshalLaunchInfo(["adb_m_id":"awesomePushMessage"])
        XCTAssertEqual(1, dictionary.count)
        XCTAssertEqual("awesomePushMessage", dictionary["pushmessageid"] as? String)
    }
    
    func test_marshalLaunchInfo_PushNotification_empty_value(){
        let dictionary = DataMarshaller.marshalLaunchInfo(["adb_m_id":""])
        XCTAssertEqual(0, dictionary.count)
    }
    
    func test_marshalLaunchInfo_LocalNotification(){
        let dictionary = DataMarshaller.marshalLaunchInfo(["adb_m_l_id":"happyBirthdayNotification"])
        XCTAssertEqual(1, dictionary.count)
        XCTAssertEqual("happyBirthdayNotification", dictionary["notificationid"] as? String)
    }
    
    func test_marshalLaunchInfo_LocalNotification_empty_value(){
        let dictionary = DataMarshaller.marshalLaunchInfo(["adb_m_l_id":""])
        XCTAssertEqual(0, dictionary.count)
    }
    
    func test_marshalLaunchInfo_EmptyDictionary(){
        let dictionary = DataMarshaller.marshalLaunchInfo([:])
        XCTAssertEqual(0, dictionary.count)
    }
    
    func test_marshalLaunchInfo_OtherKeys(){
        let dictionary = DataMarshaller.marshalLaunchInfo([
            "key_str":"stringValue",
            "key_int":99,
            "key_double":0.99,
            "key_bool":true,
            "key_dictionary":["k1":"v1"]
        ])
        XCTAssertEqual(5, dictionary.count)
        XCTAssertEqual("stringValue", dictionary["key_str"] as? String)
        XCTAssertEqual(99, dictionary["key_int"] as? Int)
        XCTAssertEqual(0.99, dictionary["key_double"] as? Double)
        XCTAssertEqual(true, dictionary["key_bool"] as? Bool)
        XCTAssertEqual(["k1":"v1"], dictionary["key_dictionary"] as? [String:String])
    }
    
}
