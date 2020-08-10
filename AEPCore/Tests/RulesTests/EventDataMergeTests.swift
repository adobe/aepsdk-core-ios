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
@testable import AEPServices
import XCTest

extension Dictionary where Key == String, Value == Any {
    func flattening(prefix: String = "") -> [String: Any] {
        let keyPrefix = (prefix.count > 0) ? (prefix + ".") : prefix
        var flattenedDict = [String: Any]()
        for (key, value) in self {
            let expandedKey = keyPrefix + key
            if let dict = value as? [String: Any] {
                flattenedDict.merge(dict.flattening(prefix: expandedKey)) { _, new in new }
            } else {
                flattenedDict[expandedKey] = value
            }
        }
        return flattenedDict
    }
}

class EventDataMergeTests: XCTestCase {
    func testSimpleMerge() {
        let toData = """
        {
            "key":"oldValue"
        }
        """.data(using: .utf8)!

        let fromData = """
        {
            "newKey":"newValue"
        }
        """.data(using: .utf8)!

        let toDict = try! JSONDecoder().decode(AnyCodable.self, from: toData).dictionaryValue!
        let fromDict = try! JSONDecoder().decode(AnyCodable.self, from: fromData).dictionaryValue!

        let result = EventDataMerger.merging(to: toDict, from: fromDict, overwrite: true)

        /*
          {
              "key":"oldValue",
             "newKey":"newValue"
          }
         */
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual("oldValue", result["key"] as? String)
        XCTAssertEqual("newValue", result["newKey"] as? String)
    }

    func testConflictAndOverwrite() {
        let toData = """
        {
            "key":"oldValue",
            "toBeDeleated" : "value"
        }
        """.data(using: .utf8)!

        let fromData = """
        {
            "key":"newValue",
            "toBeDeleated" : null
        }
        """.data(using: .utf8)!

        let toDict = try! JSONDecoder().decode(AnyCodable.self, from: toData).dictionaryValue!
        let fromDict = try! JSONDecoder().decode(AnyCodable.self, from: fromData).dictionaryValue!

        let result = EventDataMerger.merging(to: toDict, from: fromDict, overwrite: true)
        /*
          {
              "key":"newValue"
          }
         */
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual("newValue", result["key"] as? String)
    }

    func testConflictAndNotOverwrite() {
        let toData = """
        {
            "key":"oldValue",
            "donotdelete" : "value"
        }
        """.data(using: .utf8)!

        let fromData = """
        {
            "key":"newValue",
            "donotdelete" : null
        }
        """.data(using: .utf8)!

        let toDict = try! JSONDecoder().decode(AnyCodable.self, from: toData).dictionaryValue!
        let fromDict = try! JSONDecoder().decode(AnyCodable.self, from: fromData).dictionaryValue!

        let result = EventDataMerger.merging(to: toDict, from: fromDict, overwrite: false)

        /*
          {
              "key":"oldValue",
             "donotdelete":"value"
          }
         */
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual("oldValue", result["key"] as? String)
        XCTAssertEqual("value", result["donotdelete"] as? String)
    }

    func testInnerDictSimpleMerge() {
        let toData = """
        {
            "inner":{
                "key":"oldValue"
            }
        }
        """.data(using: .utf8)!

        let fromData = """
        {
            "inner": {
                "newKey":"newValue"
            }

        }
        """.data(using: .utf8)!

        let toDict = try! JSONDecoder().decode(AnyCodable.self, from: toData).dictionaryValue!
        let fromDict = try! JSONDecoder().decode(AnyCodable.self, from: fromData).dictionaryValue!

        let result = EventDataMerger.merging(to: toDict, from: fromDict, overwrite: true)

        /*
          {
             "inner": {
                 "key":"oldValue",
                 "newKey":"newValue"
              }
          }
         */
        let innerDict = result["inner"] as! [String: Any]
        XCTAssertEqual(innerDict.count, 2)
        XCTAssertEqual("oldValue", innerDict["key"] as? String)
        XCTAssertEqual("newValue", innerDict["newKey"] as? String)
    }

    func testInnerDictConflictAndOverwrite() {
        let toData = """
        {
            "inner": {
                "key":"oldValue",
                "toBeDeleated" : "value"
            }
        }
        """.data(using: .utf8)!

        let fromData = """
        {
            "inner":
            {
                "key":"newValue",
                "toBeDeleated" : null
            }
        }
        """.data(using: .utf8)!

        let toDict = try! JSONDecoder().decode(AnyCodable.self, from: toData).dictionaryValue!
        let fromDict = try! JSONDecoder().decode(AnyCodable.self, from: fromData).dictionaryValue!

        let result = EventDataMerger.merging(to: toDict, from: fromDict, overwrite: true)
        /*
          {
              "inner": {
                 "key":"newValue"
              }
          }
         */

        let innerDict = result["inner"] as! [String: Any]
        XCTAssertEqual(innerDict.count, 1)
        XCTAssertEqual("newValue", innerDict["key"] as? String)
    }

    func testInnerDictConflictAndNotOverwrite() {
        let toData = """
        {
            "inner": {
                "key":"oldValue",
                "donotdelete" : "value"
            }
        }
        """.data(using: .utf8)!

        let fromData = """
        {
            "inner": {
                "key":"newValue",
                "donotdelete" : null
            }
        }
        """.data(using: .utf8)!

        let toDict = try! JSONDecoder().decode(AnyCodable.self, from: toData).dictionaryValue!
        let fromDict = try! JSONDecoder().decode(AnyCodable.self, from: fromData).dictionaryValue!

        let result = EventDataMerger.merging(to: toDict, from: fromDict, overwrite: false)

        /*
          {
              "inner": {
                  "key":"oldValue",
                  "donotdelete":"value"
             }
          }
         */
        let innerDict = result["inner"] as! [String: Any]
        XCTAssertEqual("oldValue", innerDict["key"] as? String)
        XCTAssertEqual("value", innerDict["donotdelete"] as? String)
    }

    func testArraySimpleMerge() {
        let toData = """
        {
            "array": ["abc", "def"]
        }
        """.data(using: .utf8)!

        let fromData = """
        {
            "array": ["0", "1"]
        }
        """.data(using: .utf8)!

        let toDict = try! JSONDecoder().decode(AnyCodable.self, from: toData).dictionaryValue!
        let fromDict = try! JSONDecoder().decode(AnyCodable.self, from: fromData).dictionaryValue!

        let result = EventDataMerger.merging(to: toDict, from: fromDict, overwrite: false)

        /*
          {
             "array": ["abc", "def", "0", "1"]
          }
         */
        let array = result["array"] as! [Any]
        XCTAssertEqual(["abc", "def", "0", "1"], array as? [String])
    }

    func testArrayDuplicatedItems() {
        let toData = """
        {
            "array": ["abc", "def"]
        }
        """.data(using: .utf8)!

        let fromData = """
        {
            "array": ["abc", "def"]
        }
        """.data(using: .utf8)!

        let toDict = try! JSONDecoder().decode(AnyCodable.self, from: toData).dictionaryValue!
        let fromDict = try! JSONDecoder().decode(AnyCodable.self, from: fromData).dictionaryValue!

        let result = EventDataMerger.merging(to: toDict, from: fromDict, overwrite: false)

        /*
          {
               "array": ["abc", "def","abc", "def"]
          }
         */
        let array = result["array"] as! [Any]
        XCTAssertEqual(["abc", "def", "abc", "def"], array as? [String])
    }

    func testArrayDifferentTypes() {
        let toData = """
        {
            "array": ["abc", "def"]
        }
        """.data(using: .utf8)!

        let fromData = """
        {
            "array": [0, 1]
        }
        """.data(using: .utf8)!

        let toDict = try! JSONDecoder().decode(AnyCodable.self, from: toData).dictionaryValue!
        let fromDict = try! JSONDecoder().decode(AnyCodable.self, from: fromData).dictionaryValue!

        let result = EventDataMerger.merging(to: toDict, from: fromDict, overwrite: false)

        /*
          {
               "array": ["abc", "def",0, 1]
          }
         */
        let array = result["array"] as! [Any]
        XCTAssertEqual("abc", array[0] as? String)
        XCTAssertEqual("def", array[1] as? String)
        XCTAssertEqual(0, array[2] as? Int)
        XCTAssertEqual(1, array[3] as? Int)
    }

    func testArrayWildCardSimpleMerge() {
        let toData = """
        {
            "array": [
                {
                    "item1": "item1"
                },
                {
                    "item2": "item2"
                }
            ]
        }
        """.data(using: .utf8)!

        let fromData = """
        {
            "array[*]": {
                    "newKey": "value"
                }
        }
        """.data(using: .utf8)!

        let toDict = try! JSONDecoder().decode(AnyCodable.self, from: toData).dictionaryValue!
        let fromDict = try! JSONDecoder().decode(AnyCodable.self, from: fromData).dictionaryValue!

        let result = EventDataMerger.merging(to: toDict, from: fromDict, overwrite: false)

        /*
           {
                 "array": [
                     {
                         "item1": "item1",
                          "newKey": "value"
                     },
                     {
                         "item2": "item2",
                          "newKey": "value"
                     }
                 ]
             }
         */
        let array = result["array"] as! [[String: Any]]
        XCTAssertEqual(2, array.count)
        XCTAssertEqual(2, array[0].count)
        XCTAssertEqual("value", array[0]["newKey"] as? String)
        XCTAssertEqual("item1", array[0]["item1"] as? String)
        XCTAssertEqual(2, array[1].count)
        XCTAssertEqual("value", array[1]["newKey"] as? String)
        XCTAssertEqual("item2", array[1]["item2"] as? String)
    }

    func testArrayWildCardMergeOverwrite() {
        let toData = """
        {
            "array": [
                {
                    "item1": "item1",
                    "key": "oldValue"
                },
                {
                    "item2": "item2"
                }
            ]
        }
        """.data(using: .utf8)!

        let fromData = """
        {
            "array[*]": {
                    "key": "newValue"
                }
        }
        """.data(using: .utf8)!

        let toDict = try! JSONDecoder().decode(AnyCodable.self, from: toData).dictionaryValue!
        let fromDict = try! JSONDecoder().decode(AnyCodable.self, from: fromData).dictionaryValue!

        let result = EventDataMerger.merging(to: toDict, from: fromDict, overwrite: true)

        /*
           {
                 "array": [
                     {
                         "item1": "item1",
                         "key": "newValue"
                     },
                     {
                         "item2": "item2",
                         "key": "newValue"
                     }
                 ]
             }
         */
        let array = result["array"] as! [[String: Any]]
        XCTAssertEqual(2, array.count)
        XCTAssertEqual(2, array[0].count)
        XCTAssertEqual("newValue", array[0]["key"] as? String)
        XCTAssertEqual("item1", array[0]["item1"] as? String)
        XCTAssertEqual(2, array[1].count)
        XCTAssertEqual("newValue", array[1]["key"] as? String)
        XCTAssertEqual("item2", array[1]["item2"] as? String)
    }

    func testArrayWildCardMergeNotOverwrite() {
        let toData = """
        {
            "array": [
                {
                    "item1": "item1",
                    "key": "oldValue"
                },
                {
                    "item2": "item2"
                }
            ]
        }
        """.data(using: .utf8)!

        let fromData = """
        {
            "array[*]": {
                    "key": "newValue"
                }
        }
        """.data(using: .utf8)!

        let toDict = try! JSONDecoder().decode(AnyCodable.self, from: toData).dictionaryValue!
        let fromDict = try! JSONDecoder().decode(AnyCodable.self, from: fromData).dictionaryValue!

        let result = EventDataMerger.merging(to: toDict, from: fromDict, overwrite: false)

        /*
           {
                 "array": [
                     {
                         "item1": "item1",
                         "key": "oldValue"
                     },
                     {
                         "item2": "item2",
                         "key": "newValue"
                     }
                 ]
             }
         */
        let array = result["array"] as! [[String: Any]]
        XCTAssertEqual(2, array.count)
        XCTAssertEqual(2, array[0].count)
        XCTAssertEqual("oldValue", array[0]["key"] as? String)
        XCTAssertEqual("item1", array[0]["item1"] as? String)
        XCTAssertEqual(2, array[1].count)
        XCTAssertEqual("newValue", array[1]["key"] as? String)
        XCTAssertEqual("item2", array[1]["item2"] as? String)
    }

    func testArrayWildCardInnerMapMergeOverwrite() {
        let toData = """
        {
            "array": [
                {
                    "item1": "item1",
                    "key": "oldValue",
                    "inner" : {
                        "innerKey": "oldValue",
                        "notToMerge": "oldValue"

                    }
                },
                {
                    "item2": "item2"
                }
            ]
        }
        """.data(using: .utf8)!

        let fromData = """
        {
            "array[*]": {
                    "key": "newValue",
                    "inner" : {
                        "innerKey": "newValue",
                        "newKey": "newValue",
                    }
                }
        }
        """.data(using: .utf8)!

        let toDict = try! JSONDecoder().decode(AnyCodable.self, from: toData).dictionaryValue!
        let fromDict = try! JSONDecoder().decode(AnyCodable.self, from: fromData).dictionaryValue!

        let result = EventDataMerger.merging(to: toDict, from: fromDict, overwrite: true)

        /*
           {
                 "array": [
                     {
                         "item1": "item1",
                         "key": "newValue",
                         "inner" : {
                             "innerKey": "newValue",
                             "newKey": "newValue",
                             "notToMerge": "oldValue"

                         }
                     },
                     {
                         "item2": "item2",
                         "key": "newValue",
                          "inner" : {
                              "innerKey": "newValue",
                              "newKey": "newValue"

                          }
                     }
                 ]
             }
         */
        let array = result["array"] as! [[String: Any]]
        let innerDict1 = array[0]["inner"] as? [String: String]
        XCTAssertEqual(3, innerDict1?.count)
        XCTAssertEqual("newValue", innerDict1?["innerKey"])

        let innerDict2 = array[1]["inner"] as? [String: String]
        XCTAssertEqual(2, innerDict2?.count)
    }

    func testArrayWildCardInnerMapNotMergeOverwrite() {
        let toData = """
        {
            "array": [
                {
                    "item1": "item1",
                    "key": "oldValue",
                    "inner" : {
                        "innerKey": "oldValue",
                        "notToMerge": "oldValue"

                    }
                },
                {
                    "item2": "item2"
                }
            ]
        }
        """.data(using: .utf8)!

        let fromData = """
        {
            "array[*]": {
                    "key": "newValue",
                    "inner" : {
                        "innerKey": "newValue",
                        "newKey": "newValue",
                    }
                }
        }
        """.data(using: .utf8)!

        let toDict = try! JSONDecoder().decode(AnyCodable.self, from: toData).dictionaryValue!
        let fromDict = try! JSONDecoder().decode(AnyCodable.self, from: fromData).dictionaryValue!

        let result = EventDataMerger.merging(to: toDict, from: fromDict, overwrite: false)

        /*
           {
                 "array": [
                     {
                         "item1": "item1",
                         "key": "newValue",
                         "inner" : {
                             "innerKey": "oldValue",
                             "newKey": "newValue",
                             "notToMerge": "oldValue"

                         }
                     },
                     {
                         "item2": "item2",
                         "key": "newValue",
                          "inner" : {
                              "innerKey": "newValue",
                              "newKey": "newValue"

                          }
                     }
                 ]
             }
         */
        let array = result["array"] as! [[String: Any]]
        let innerDict1 = array[0]["inner"] as? [String: String]
        XCTAssertEqual(3, innerDict1?.count)
        XCTAssertEqual("oldValue", innerDict1?["innerKey"])

        let innerDict2 = array[1]["inner"] as? [String: String]
        XCTAssertEqual(2, innerDict2?.count)
    }

    func testArrayContainsNoneMapItem() {
        let toData = """
        {
            "array": [
                {
                    "item1": "item1"
                },
                "stringItem"
            ]
        }
        """.data(using: .utf8)!

        let fromData = """
        {
            "array[*]": {
                "key": "newValue"
            }
        }
        """.data(using: .utf8)!

        let toDict = try! JSONDecoder().decode(AnyCodable.self, from: toData).dictionaryValue!
        let fromDict = try! JSONDecoder().decode(AnyCodable.self, from: fromData).dictionaryValue!

        let result = EventDataMerger.merging(to: toDict, from: fromDict, overwrite: false)

        /*
           {
             "array": [
                 {
                     "item1": "item1",
                     "key": "newValue"
                 },
                 "stringItem"
             ]
           }
         */

        let array = result["array"] as! [Any]
        XCTAssertEqual(2, array.count)
        let item1 = array[0] as? [String: String]

        XCTAssertEqual("newValue", item1?["key"])
        XCTAssertEqual("item1", item1?["item1"])
        XCTAssertEqual("stringItem", array[1] as? String)
    }

    func testArrayWildCardNoTarget() {
        let toData = """
        {
        }
        """.data(using: .utf8)!

        let fromData = """
        {
            "array[*]": {
                "key": "newValue"
            }
        }
        """.data(using: .utf8)!

        let toDict = try! JSONDecoder().decode(AnyCodable.self, from: toData).dictionaryValue!
        let fromDict = try! JSONDecoder().decode(AnyCodable.self, from: fromData).dictionaryValue!

        let result = EventDataMerger.merging(to: toDict, from: fromDict, overwrite: false)

        /*
           {
           }
         */
        XCTAssertEqual(0, result.count)
    }

    func testInnerMapContainArrayWildCardMergeOverwrite() {
        let toData = """
        {
            "innerMap": {
                 "array": [
                     {
                         "item1": "item1"
                     },
                    {
                        "item2": "item2"
                    }
                ]
             }
        }
        """.data(using: .utf8)!

        let fromData = """
        {
             "innerMap": {
                "array[*]": {
                        "key": "newValue"
                    }
             }
        }
        """.data(using: .utf8)!

        let toDict = try! JSONDecoder().decode(AnyCodable.self, from: toData).dictionaryValue!
        let fromDict = try! JSONDecoder().decode(AnyCodable.self, from: fromData).dictionaryValue!

        let result = EventDataMerger.merging(to: toDict, from: fromDict, overwrite: true)

        /*
           {
              "innerMap": {
                 "array": [
                     {
                         "item1": "item1",
                         "key": "newValue"
                     },
                     {
                         "item2": "item2",
                         "key": "newValue"
                     }
                 ]
              }
          }
         */
        let array = (result["innerMap"] as! [String: Any])["array"] as? [[String: String]]
        XCTAssertEqual(2, array?.count)
        XCTAssertEqual(2, array?[0].count)
        XCTAssertEqual(2, array?[1].count)
    }

    func testCleanArrayWildCard() {
        let toData = """
        {
        }
        """.data(using: .utf8)!

        let fromData = """
        {
             "innerMap": {
                "array[*]": {
                        "key": "newValue"
                    }
             },
             "array[*]": {
                   "key": "newValue"
               }
        }
        """.data(using: .utf8)!

        let toDict = try! JSONDecoder().decode(AnyCodable.self, from: toData).dictionaryValue!
        let fromDict = try! JSONDecoder().decode(AnyCodable.self, from: fromData).dictionaryValue!

        let result = EventDataMerger.merging(to: toDict, from: fromDict, overwrite: true)

        /*
           {
              "innerMap": {
              }
          }
         */

        XCTAssertEqual(1, result.count)
        let innerMap = result["innerMap"] as! [String: Any]
        XCTAssertEqual(0, innerMap.count)
    }
}
