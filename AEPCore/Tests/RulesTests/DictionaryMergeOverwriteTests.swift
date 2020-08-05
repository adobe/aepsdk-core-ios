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

class DictionaryMergeOverwriteTests: XCTestCase {
    
    /*
    toDict:
     {
        "key1": "value1",
        "key2": "value2",
        "anInt": 552,
        "innerDict": {
            "embeddedString": "embeddedStringValue"
            "embeddedDict": {
                "embeddedDictKey": "embeddedDictValue"
            }
        },
        "aList": [
            "stringInList"
        ],
        "listOfObjects": [
            {
                "name": "request1",
                "details": {
                    "size": "large",
                    "color": "red"
                }
            },
            {
                "name": "request2",
                "location": "central"
            }
        ]
     }
     */
    private func getToDict() -> [String: Any?] {
        var dict: [String: Any?] = [:]
        dict["key1"] = "value1"
        dict["key2"] = "value2"
        dict["anInt"] = 552
        var innerDict: [String: Any?] = [:]
        innerDict["embeddedString"] = "embeddedStringValue"
        let embeddedDict: [String: Any?] = ["embeddedDictKey": "embeddedDictValue"]
        innerDict["embeddedDict"] = embeddedDict
        dict["innerDict"] = innerDict
        let aList: [Any?] = ["stringInlist"]
        dict["aList"] = aList
        var arrOfObjs: [Any?] = []
        var obj1: [String: Any?] = [:]
        obj1["name"] = "request1"
        var obj1Details: [String: Any?] = [:]
        obj1Details["size"] = "large"
        obj1Details["color"] = "red"
        obj1["details"] = obj1Details
        var obj2: [String: Any?] = [:]
        obj2["name"] = "request2"
        obj2["location"] = "central"
        arrOfObjs.append(obj1)
        arrOfObjs.append(obj2)
        dict["listOfObjects"] = arrOfObjs
        return dict
    }
    
    /*
    {
        "attachedKey": "attachedValue",
        "key1": "updatedValue1",
        "newInt": 123,
        "newDouble": 32.23,
        "newBool": false,
        "newNil": nil,
        "innerDict": {
            "embeddedString": "changedEmbeddedStringValue",
            "newEmbeddedString": "newEmbeddedStringValue",
            "embeddedDict": {
                "embeddedDictKey": "newEmbeddedDictValue"
            }
        },
        "newDict": {
            "newDictKey": "newDictValue"
        },
        "aList": [
            "stringInList",   // <<< this is a duplicate entry, we need to make sure we don't get 2
            "newStringInList"
        ],
        "newList": [
            "newListString"
        ],
        "listOfObjects[*]": {
            "details": {
                "color": "orange",
                "temp": 58.8
             }
        }
     }
     */
    private func getFromDict() -> [String: Any?] {
        var fromDict: [String: Any?] = [:]
        
        fromDict["attachedKey"] = "attachedValue"
        fromDict["key1"] = "updatedValue1"
        fromDict["newInt"] = Int(123)
        fromDict["newDouble"] = Double(32.23)
        fromDict["newBool"] = false
        fromDict.updateValue(nil, forKey: "newNil")
        var innerDict: [String: Any?] = [:]
        innerDict["embeddedString"] = "changedEmbeddedStringValue"
        innerDict["newEmbeddedString"] = "newEmbeddedStringValue"
        let embeddedDict: [String: Any?] = ["embeddedDictKey": "newEmbeddedDictValue"]
        innerDict["embeddedDict"] = embeddedDict
        fromDict["innerDict"] = innerDict
        let newDict: [String: Any?] = ["newDictKey":"newDictValue"]
        fromDict["newDict"] = newDict
        let aList: [Any?] = ["stringInList", "newStringInList"]
        fromDict["aList"] = aList
        let newList: [Any?] = ["newListString"]
        fromDict["newList"] = newList
        var listOfObjectsAsDict: [String: Any?] = [:]
        var details: [String: Any?] = [:]
        details["color"] = "orange"
        details["temp"] = Double(58.8)
        listOfObjectsAsDict["details"] = details
        fromDict["listOfObjects[*]"] = listOfObjectsAsDict
        return fromDict
    }
    
    ///
    /// Sets values to nil and makes sure they have been properly removed when `deleteIfEmpty` is true
    ///
    func testAddDataToDictWithDelete() {
        var fromDict = getFromDict()
        fromDict.updateValue(nil, forKey: "key2")
        fromDict.updateValue(nil, forKey: "innerDict")
        fromDict.updateValue(nil, forKey: "aList")
        fromDict.updateValue(nil, forKey: "listOfObjects[*]")
        var toDict = getToDict()
        toDict.mergeOverwrite(new: fromDict, deleteIfEmpty: true)
        XCTAssertEqual(toDict.count, 8)
        XCTAssertEqual(toDict["key1"] as? String, "updatedValue1")
        XCTAssertFalse(toDict.keys.contains("key2"))
        XCTAssertEqual(toDict["anInt"] as? Int, 552)
        XCTAssertEqual(toDict["newInt"] as? Int, 123)
        XCTAssertEqual(toDict["newDouble"] as? Double, 32.23)
        XCTAssertFalse(toDict["newBool"] as! Bool)
        XCTAssertFalse(toDict.keys.contains("newNil"))
        XCTAssertFalse(toDict.keys.contains("innerDict"))
        
        let newDict = toDict["newDict"] as? [String: Any?]
        XCTAssertEqual(newDict?["newDictKey"] as? String, "newDictValue")
        XCTAssertFalse(toDict.keys.contains("aList"))
        
        let newList = toDict["newList"] as? [Any?]
        XCTAssertEqual(newList?.count, 1)
        XCTAssertEqual(newList?[0] as? String, "newListString")
    }
    
    /**
     "listOfObjects": [
         {
             "name": "request1",
             "details": {
                 "color": "red"
                 "temp": 58.8
             }
         },
         {
             "name": "request2",
             "location": "central"
             "details": {
                 "temp": 58.8
             }
         }
     ]
     */
    ///
    /// Tests attach data with modified nil values for the incoming data, at both the main level, and the inner dictionary level
    ///
    func testAddDataToDictWithInnerDelete() {
        var fromDict = getFromDict()
        fromDict.updateValue(nil, forKey: "key2")
        fromDict.updateValue(nil, forKey: "innerDict")
        fromDict.updateValue(nil, forKey: "aList")
        var objectDict: [String: Any?] = [:]
        var innerDetails: [String: Any?] = [:]
        innerDetails.updateValue(nil, forKey: "size")
        innerDetails.updateValue(Double(58.8), forKey: "temp")
        objectDict["details"] = innerDetails
        fromDict["listOfObjects[*]"] = objectDict
        
        var toDict = getToDict()
        toDict.mergeOverwrite(new: fromDict, deleteIfEmpty: true)
        
        XCTAssertEqual(toDict.count, 9)
        XCTAssertTrue(toDict.keys.contains("attachedKey"))
        XCTAssertEqual(toDict["attachedKey"] as? String, "attachedValue")
        XCTAssertEqual(toDict["key1"] as? String, "updatedValue1")
        XCTAssertEqual(toDict["anInt"] as? Int, 552)
        XCTAssertEqual(toDict["newInt"] as? Int, 123)
        XCTAssertEqual(toDict["newDouble"] as? Double, 32.23)
        XCTAssertFalse(toDict["newBool"] as! Bool)
        
        let newDict: [String: Any?] = toDict["newDict"] as? [String: Any?] ?? [:]
        XCTAssertEqual(newDict["newDictKey"] as? String, "newDictValue")
        
        let newList: [Any?] = toDict["newList"] as? [Any?] ?? []
        XCTAssertEqual(newList.count, 1)
        XCTAssertEqual(newList[0] as? String, "newListString")
        
        // Deleted keys
        XCTAssertFalse(toDict.keys.contains("key2"))
        XCTAssertFalse(toDict.keys.contains("innerDict"))
        XCTAssertFalse(toDict.keys.contains("aList"))
        XCTAssertFalse(toDict.keys.contains("newNil"))
        
        // Inner delete from listOfObjects
        let listOfObjects: [Any?] = toDict["listOfObjects"] as? [Any?] ?? []
        XCTAssertEqual(listOfObjects.count, 2)
        
        let obj1: [String: Any?] = listOfObjects[0] as? [String: Any?] ?? [:]
        XCTAssertEqual(obj1.count, 2)
        XCTAssertEqual(obj1["name"] as? String, "request1")
        let obj1Details: [String: Any?] = obj1["details"] as? [String: Any?] ?? [:]
        XCTAssertEqual(obj1Details.count, 2)
        XCTAssertEqual(obj1Details["color"] as? String, "red")
        XCTAssertFalse(obj1Details.keys.contains("size"))
        XCTAssertEqual(obj1Details["temp"] as? Double, 58.8)
        
        let obj2: [String: Any?] = listOfObjects[1] as? [String: Any?] ?? [:]
        XCTAssertEqual(obj2.count, 3)
        XCTAssertEqual(obj2["name"] as? String, "request2")
        XCTAssertEqual(obj2["location"] as? String, "central")
        let obj2Details: [String: Any?] = obj2["details"] as? [String: Any?] ?? [:]
        XCTAssertEqual(obj2Details.count, 1)
        XCTAssertEqual(obj2Details["temp"] as? Double, 58.8)
    }
    
    ///
    /// Tests modifying a nested dict works as expected
    ///
    func testModifyNestedDict() {
        var toDict = getToDict()
        toDict.mergeOverwrite(new: getFromDict(), deleteIfEmpty: true)
        
        let innerDict = toDict["innerDict"] as? [String: Any?] ?? [:]
        let nestedDict = innerDict["embeddedDict"] as? [String: Any?] ?? [:]
        XCTAssertEqual(nestedDict["embeddedDictKey"] as? String, "newEmbeddedDictValue")
    }
    
    ///
    /// Tests modifying the inner dictionary with a nil value
    ///
    func testModifyInnerDictWithNil() {
        var toDict = getToDict()
        var fromDict = getFromDict()
        
        var innerDict = fromDict["innerDict"] as? [String: Any?] ?? [:]
        innerDict.updateValue(nil, forKey: "newEmbeddedString")
        fromDict["innerDict"] = innerDict
        toDict.mergeOverwrite(new: fromDict, deleteIfEmpty: true)
        let resultInnerDict = toDict["innerDict"] as? [String: Any?] ?? [:]
        XCTAssertFalse(resultInnerDict.keys.contains("newEmbeddedString"))
    }
    
    ///
    /// Tests modifying a nested dict with a nil value properly removes it
    ///
    func testModifyNestedDictWithNil() {
        var toDict = getToDict()
        var fromDict = getFromDict()
        
        // Update the nested dictionary with a nil value
        var innerDict = fromDict["innerDict"] as? [String: Any?] ?? [:]
        var nestedDict = innerDict["embeddedDict"] as? [String: Any?] ?? [:]
        nestedDict.updateValue(nil, forKey: "embeddedDictKey")
        innerDict.updateValue(nestedDict, forKey: "embeddedDict")
        fromDict.updateValue(innerDict, forKey: "innerDict")
        
        toDict.mergeOverwrite(new: fromDict, deleteIfEmpty: true)
        
        innerDict = toDict["innerDict"] as? [String: Any?] ?? [:]
        nestedDict = innerDict["embeddedDict"] as? [String: Any?] ?? [:]
        XCTAssertFalse(nestedDict.keys.contains("embeddedDictKey"))
    }
    
    ///
    /// Adds data without any nil values. Performs an attach data using the suffix for object
    /// The receiver of the attach data `listOfObjects` has an internal dictionary value which has another dictionary who's key is "details"
    /// while the incoming attach data also has a key named "details"
    /// Makes sure that the incoming details object is properly added to the members of `listOfObjects`
    ///
    func testAddDataToDictWithNoNilValues() {
        var toDict = getToDict()
        toDict.mergeOverwrite(new: getFromDict(), deleteIfEmpty: true)
        XCTAssertEqual(toDict.count, 12)
        XCTAssertEqual(toDict["attachedKey"] as? String, "attachedValue")
        XCTAssertEqual(toDict["key1"] as? String, "updatedValue1")
        XCTAssertEqual(toDict["key2"] as? String, "value2")
        XCTAssertEqual(toDict["anInt"] as? Int, 552)
        XCTAssertEqual(toDict["newInt"] as? Int, 123)
        XCTAssertEqual(toDict["newDouble"] as? Double, 32.23)
        XCTAssertFalse(toDict["newBool"] as! Bool)
        
        let innerDict = toDict["innerDict"] as? [String: Any?] ?? [:]
        XCTAssertEqual(innerDict["embeddedString"] as? String, "changedEmbeddedStringValue")
        XCTAssertEqual(innerDict["newEmbeddedString"] as? String, "newEmbeddedStringValue")
        
        let newDict = toDict["newDict"] as? [String: Any?] ?? [:]
        XCTAssertEqual(newDict["newDictKey"] as? String, "newDictValue")
        
        let aList = toDict["aList"] as? [Any?] ?? []
        XCTAssertEqual(aList.count, 2)
        XCTAssertEqual(aList[0] as? String, "stringInList")
        XCTAssertEqual(aList[1] as? String, "newStringInList")
        
        let listOfObjects = toDict["listOfObjects"] as? [Any?] ?? []
        XCTAssertEqual(listOfObjects.count, 2)
        
        let obj1 = listOfObjects[0] as? [String: Any?] ?? [:]
        XCTAssertEqual(obj1.count, 2)
        XCTAssertEqual(obj1["name"] as? String, "request1")
        
        let obj1Details = obj1["details"] as? [String: Any?] ?? [:]
        XCTAssertEqual(obj1Details.count, 3)
        XCTAssertEqual(obj1Details["color"] as? String, "orange")
        XCTAssertEqual(obj1Details["size"] as? String, "large")
        XCTAssertEqual(obj1Details["temp"] as? Double, 58.8)
 
        let obj2 = listOfObjects[1] as? [String: Any?] ?? [:]
        XCTAssertEqual(obj2.count, 3)
        XCTAssertEqual(obj2["name"] as? String, "request2")
        XCTAssertEqual(obj2["location"] as? String, "central")
        
        let obj2Details = obj2["details"] as? [String: Any?] ?? [:]
        XCTAssertEqual(obj2Details.count, 2)
        XCTAssertEqual(obj2Details["color"] as? String, "orange")
        XCTAssertEqual(obj2Details["temp"] as? Double, 58.8)
    }
    
    ///
    /// Tests that multiple attach data items are properly attached
    ///
    func testMultipleAttachDataItemsWithOneDeletingInner() {
        var toDict = getToDict()
        var fromDict = getFromDict()
        
        var toObjectDict: [String: Any?] = [:]
        var toInnerDetails: [String: Any?] = [:]
        var toInnerArrayOfObjs: [Any?] = []
        toInnerDetails["country"] = "USA"
        toInnerDetails["state"] = "UT"
        toObjectDict["localeDetails"] = toInnerDetails
        toInnerArrayOfObjs.append(toObjectDict)
        toDict["anotherListOfObjects"] = toInnerArrayOfObjs
        
        var fromObjectDict: [String: Any?] = [:]
        var fromInnerDetails: [String: Any?] = [:]
        fromInnerDetails["country"] = "USA"
        fromInnerDetails.updateValue(nil, forKey: "state")
        fromObjectDict["localeDetails"] = fromInnerDetails
        fromDict["anotherListOfObjects[*]"] = fromObjectDict
        
        toDict.mergeOverwrite(new: fromDict, deleteIfEmpty: true)
        
        // Inner delete from listOfObjects
        let listOfObjects: [Any?] = toDict["listOfObjects"] as? [Any?] ?? []
        XCTAssertEqual(listOfObjects.count, 2)
        
        let obj1: [String: Any?] = listOfObjects[0] as? [String: Any?] ?? [:]
        XCTAssertEqual(obj1.count, 2)
        XCTAssertEqual(obj1["name"] as? String, "request1")
        let obj1Details: [String: Any?] = obj1["details"] as? [String: Any?] ?? [:]
        XCTAssertEqual(obj1Details.count, 3)
        XCTAssertEqual(obj1Details["color"] as? String, "orange")
        XCTAssertEqual(obj1Details["size"] as? String, "large")
        XCTAssertEqual(obj1Details["temp"] as? Double, 58.8)
        
        let obj2: [String: Any?] = listOfObjects[1] as? [String: Any?] ?? [:]
        XCTAssertEqual(obj2.count, 3)
        XCTAssertEqual(obj2["name"] as? String, "request2")
        XCTAssertEqual(obj2["location"] as? String, "central")
        let obj2Details: [String: Any?] = obj2["details"] as? [String: Any?] ?? [:]
        XCTAssertEqual(obj2Details.count, 2)
        XCTAssertEqual(obj2Details["temp"] as? Double, 58.8)
        XCTAssertEqual(obj2Details["color"] as? String, "orange")
        
        // Second attach data object
        let anotherListOfObjects: [Any?] = toDict["anotherListOfObjects"] as? [Any?] ?? []
        XCTAssertEqual(anotherListOfObjects.count, 1)
        
        let anotherObj1: [String: Any?] = anotherListOfObjects[0] as? [String: Any?] ?? [:]
        XCTAssertEqual(anotherObj1.count, 1)
        let anotherObj1Details: [String: Any?] = anotherObj1["localeDetails"] as? [String: Any?] ?? [:]
        XCTAssertEqual(anotherObj1Details.count, 1)
        XCTAssertEqual(anotherObj1Details["country"] as? String, "USA")
        XCTAssertFalse(anotherObj1Details.keys.contains("state"))
    }
    
    ///
    /// Tests that nil values are not deleted when `deleteIfEmpty` is false
    ///
    func testNoNilDelete() {
        var fromDict = getFromDict()
        fromDict.updateValue(nil, forKey: "key2")
        fromDict.updateValue(nil, forKey: "innerDict")
        fromDict.updateValue(nil, forKey: "aList")
        fromDict.updateValue(nil, forKey: "listOfObjects[*]")
        var toDict = getToDict()
        toDict.mergeOverwrite(new: fromDict, deleteIfEmpty: false)
        print("toDict: \(toDict)")
        print("fromDict: \(fromDict)")
        XCTAssertEqual(toDict.count, 14)
        XCTAssertEqual(toDict["key1"] as? String, "updatedValue1")
        XCTAssertTrue(toDict.keys.contains("key2"))
        XCTAssertEqual(toDict["anInt"] as? Int, 552)
        XCTAssertEqual(toDict["newInt"] as? Int, 123)
        XCTAssertEqual(toDict["newDouble"] as? Double, 32.23)
        XCTAssertFalse(toDict["newBool"] as! Bool)
        XCTAssertTrue(toDict.keys.contains("newNil"))
        XCTAssertTrue(toDict.keys.contains("innerDict"))
        
        let newDict = toDict["newDict"] as? [String: Any?]
        XCTAssertEqual(newDict?["newDictKey"] as? String, "newDictValue")
        XCTAssertTrue(toDict.keys.contains("aList"))
        
        let newList = toDict["newList"] as? [Any?]
        XCTAssertEqual(newList?.count, 1)
        XCTAssertEqual(newList?[0] as? String, "newListString")
    }
}
