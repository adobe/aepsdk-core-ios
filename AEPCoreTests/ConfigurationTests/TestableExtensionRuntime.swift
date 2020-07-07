//
//  MockExtensionRuntime.swift
//  AEPCoreTests
//
//  Created by Jiabin Geng on 7/7/20.
//  Copyright © 2020 Adobe. All rights reserved.
//

import Foundation
@testable import AEPCore

class TestableExtensionRuntime:ExtensionRuntime{
    var listeners:[String:EventListener] = [:]
    var dispatchedEvents: [Event] = []
    var createdSharedStates: [[String : Any]] = []
    var otherSharedStates: [String: (value: [String : Any]?, status: SharedStateStatus)] = [:]
    
    func getListener(type: EventType, source: EventSource) -> EventListener?{
        return listeners["\(type)-\(source)"]
    }
    
    func simulateComingEvent(event:Event){
        listeners["\(event.type)-\(event.source)"]?(event)
        listeners["\(EventType.wildcard)-\(EventSource.wildcard)"]?(event)
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
        return nil
    }
    
    func simulateSharedState(extensionName: String, event: Event?, data: (value: [String : Any]?, status: SharedStateStatus)){
        otherSharedStates["\(extensionName)-\(String(describing: event?.id))"] = data
    }
    
    func startEvents() {
    }
    
    func stopEvents() {
    }
    
    
}
