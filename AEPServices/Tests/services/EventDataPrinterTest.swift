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

@testable import AEPServices
import XCTest

class EventDataPrinterTest: XCTestCase {
    func testPrintEventData_as_AnyObject() throws {
        var dict = [String: Any]()
        dict = [
            "a": "13435454",
            "b":[
                "b1": 1235566,
                "b2": LogLevel.debug
            ]
        ]
        let output = "\(prettyEventData: dict)"
        let expected = """
        {
            a = 13435454;
            b = {
                b1 = 1235566;
                b2 = "AEPServices.LogLevel";
            };
        }
        """
        print(output)
        print(expected)
    }
    func testPrintEventData_with_prettyFormat() throws {
        var dict = [String: Any]()
        dict = [
            "a": "13435454",
            "b":[
                "b1": 1235566,
                "b2": "12.45"
            ]
        ]
        let output = "\(prettyEventData: dict)"
        let expected = """
        {
          "a" : "13435454",
          "b" : {
            "b1" : 1235566,
            "b2" : "12.45"
          }
        }
        """
        print(output)
        print(expected)
    }
}


