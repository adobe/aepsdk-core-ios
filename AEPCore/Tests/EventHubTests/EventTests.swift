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

import XCTest

@testable import AEPCore

class EventTest: XCTestCase {
    
    func testCopyWithNewData() {
        let data: [String: Any] = [ "k1": "v1", "k2": "v2"]
        let event = Event(name: "name", type: "type", source: "source", data: data)
        
        let newData: [String: Any] = [ "nk1": "nv1", "nk2": "nv2"]
        let newEvent = event.copyWithNewData(data: newData)
        
        XCTAssertEqual(event.id, newEvent.id)
        XCTAssertEqual(event.name, newEvent.name)
        XCTAssertEqual(event.timestamp, newEvent.timestamp)
        XCTAssertEqual(event.source, newEvent.source)
        XCTAssertEqual(event.type, newEvent.type)
        
        let eventData = event.data ?? [:]
        XCTAssertTrue(NSDictionary(dictionary: eventData).isEqual(to: data))
        
        let newEventData = newEvent.data ?? [:]
        XCTAssertTrue(NSDictionary(dictionary: newEventData).isEqual(to: newData))
    }
    
    func testCopyWithNewDataResponseEvent() {
        let requestEvent = Event(name: "name", type: "type", source: "source", data: nil)
        
        let data: [String: Any] = [ "k1": "v1", "k2": "v2"]
        let responseEvent = requestEvent.createResponseEvent(name: "responseEvent", type: "type", source: "source", data: data)
        
        let newData: [String: Any] = [ "nk1": "nv1", "nk2": "nv2"]
        let newEvent = responseEvent.copyWithNewData(data: newData)
        
        XCTAssertEqual(responseEvent.id, newEvent.id)
        XCTAssertEqual(responseEvent.name, newEvent.name)
        XCTAssertEqual(responseEvent.timestamp, newEvent.timestamp)
        XCTAssertEqual(responseEvent.source, newEvent.source)
        XCTAssertEqual(responseEvent.type, newEvent.type)
        XCTAssertEqual(responseEvent.responseID, newEvent.responseID)
        XCTAssertNotNil(responseEvent.responseID)
        
        let eventData = responseEvent.data ?? [:]
        XCTAssertTrue(NSDictionary(dictionary: eventData).isEqual(to: data))
        
        let newEventData = newEvent.data ?? [:]
        XCTAssertTrue(NSDictionary(dictionary: newEventData).isEqual(to: newData))
    }
    
    func testCreateResponseEventUsesParentID() {
        let parentEvent = Event(name: "parent event", type: "type", source: "source", data: ["parent": "data"])
        let childName = "child event"
        let childType = "child type"
        let childSource = "child source"
        let childDataKey = "child"
        let childDataValue = "data"
        let childEvent = parentEvent.createResponseEvent(name: childName, type: childType, source: childSource, data: [childDataKey: childDataValue])
        
        XCTAssertEqual(childEvent.parentID, parentEvent.id)
        XCTAssertEqual(childEvent.responseID, parentEvent.id)
        XCTAssertEqual(childEvent.name, childName)
        XCTAssertEqual(childEvent.type, childType)
        XCTAssertEqual(childEvent.source, childSource)
        XCTAssertEqual(childEvent.data?[childDataKey] as? String, childDataValue)
        
    }
    
    func testCreateChainedEventUsesParentID() {
        let parentEvent = Event(name: "parent event", type: "type", source: "source", data: ["parent": "data"])
        let childName = "child event"
        let childType = "child type"
        let childSource = "child source"
        let childDataKey = "child"
        let childDataValue = "data"
        let childMaskValue = ["testMask"]
        let childEvent = parentEvent.createChainedEvent(name: childName, type: childType, source: childSource, data: [childDataKey: childDataValue], mask: childMaskValue)
        
        XCTAssertEqual(childEvent.parentID, parentEvent.id)
        XCTAssertEqual(childEvent.name, childName)
        XCTAssertEqual(childEvent.type, childType)
        XCTAssertEqual(childEvent.source, childSource)
        XCTAssertEqual(childEvent.data?[childDataKey] as? String, childDataValue)
        XCTAssertEqual(childEvent.mask, childMaskValue)
    }
    
    func testCopyWithNewDataChainedEvent() {
        let requestEvent = Event(name: "name", type: "type", source: "source", data: nil)
        
        let data: [String: Any] = [ "k1": "v1", "k2": "v2"]
        let chainedEvent = requestEvent.createChainedEvent(name: "chainedEvent", type: "type", source: "source", data: data)
        
        let newData: [String: Any] = [ "nk1": "nv1", "nk2": "nv2"]
        let newEvent = chainedEvent.copyWithNewData(data: newData)
        
        XCTAssertEqual(chainedEvent.id, newEvent.id)
        XCTAssertEqual(chainedEvent.name, newEvent.name)
        XCTAssertEqual(chainedEvent.timestamp, newEvent.timestamp)
        XCTAssertEqual(chainedEvent.source, newEvent.source)
        XCTAssertEqual(chainedEvent.type, newEvent.type)
        XCTAssertEqual(chainedEvent.parentID, requestEvent.id)
        
        let eventData = chainedEvent.data ?? [:]
        XCTAssertTrue(NSDictionary(dictionary: eventData).isEqual(to: data))
        
        let newEventData = newEvent.data ?? [:]
        XCTAssertTrue(NSDictionary(dictionary: newEventData).isEqual(to: newData))
    }
}
