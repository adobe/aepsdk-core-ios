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

import Foundation
@testable import AEPCore

// Testable implemetation for `ExtensionRuntime`, enable easy setup for the input and verification of the output of an extension
class TestableExtensionRuntime:ExtensionRuntime{
    
    var listeners:[String:EventListener] = [:]
    var dispatchedEvents: [Event] = []
    var createdSharedStates: [[String : Any]?] = []
    var mockedSharedStates: [String: (value: [String : Any]?, status: SharedStateStatus)] = [:]
    
    func getListener(type: EventType, source: EventSource) -> EventListener?{
        return listeners["\(type)-\(source)"]
    }
    
    func simulateComingEvents(_ events:Event...){        
        for event in events {
            listeners["\(event.type)-\(event.source)"]?(event)
            listeners["\(EventType.wildcard)-\(EventSource.wildcard)"]?(event)
        }
    }
    
    func registerListener(type: EventType, source: EventSource, listener: @escaping EventListener) {
        listeners["\(type)-\(source)"] = listener
    }
    
    
    func dispatch(event: Event) {
        dispatchedEvents += [event]
    }
    
    func createSharedState(data: [String : Any], event: Event?) {
        self.createdSharedStates += [data]
    }
    
    func createPendingSharedState(event: Event?) -> SharedStateResolver {
        return { data in
            self.createdSharedStates += [data]
        }
    }
    
    func getSharedState(extensionName: String, event: Event?) -> (value: [String : Any]?, status: SharedStateStatus)? {
        if let id = event?.id{
            return mockedSharedStates["\(extensionName)-\(id)"] ?? mockedSharedStates["\(extensionName)"]
        }
        return  mockedSharedStates["\(extensionName)"]
    }
    
    func simulateSharedState(for pair:(extensionName: String, event: Event), data: (value: [String : Any]?, status: SharedStateStatus)){
        mockedSharedStates["\(pair.extensionName)-\(pair.event.id)"] = data
    }
    
    func simulateSharedState(for extensionName: String, data: (value: [String : Any]?, status: SharedStateStatus)){
        mockedSharedStates["\(extensionName)"] = data
    }
    
    func startEvents() {
    }
    
    func stopEvents() {
    }
    
    func resetDispatchedEventAndCreatedSharedStates(){
        dispatchedEvents = []
        createdSharedStates = []
    }
    
    
}

extension Event{
    func copyWithNewTimeStamp(_ timestamp: Date) -> Event{
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try! encoder.encode(self)
        var json = try! JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]
        json?["timestamp"] = timestamp.timeIntervalSinceReferenceDate
        let jsonData = try! JSONSerialization.data(withJSONObject: json as Any, options: .prettyPrinted)

        let newEvent = try! decoder.decode(Event.self, from: jsonData)
        return newEvent
    }
}
