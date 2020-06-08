//
//  SampleExtensionTests.swift
//  SampleExtensionTests
//
//  Created by Jiabin Geng on 6/8/20.
//  Copyright © 2020 Adobe. All rights reserved.
//

import XCTest
@testable import SampleExtension
@testable import AEPCore


class ExtensionRuntimeEnv{
    var listernerMapping: [String: Array<EventListener>] = [:]
    var receivedEvents: [Event] = []
    
    
    func registerListener(type: EventType, source: EventSource, listener: @escaping EventListener){
        let listerns = listernerMapping[type.rawValue + source.rawValue] ?? []
        listernerMapping[type.rawValue + source.rawValue] = listerns + [listener]
    }
    
    func simulateEvent(type: EventType, source: EventSource, event: Event){
        let listerns = listernerMapping[type.rawValue + source.rawValue] ?? []
        listerns.forEach { listener in
            listener(event)
        }
    }
    
    func dispatch(event: Event) {
        receivedEvents += [event]
    }
    
    func createSharedState(extensionName:String, data: [String: Any], event: Event?) {
      }

      func createPendingSharedState(extensionName:String,event: Event?) -> SharedStateResolver {
        return  { data in
        }
      }

      func getSharedState(extensionName: String, event: Event?) -> (value: [String: Any]?, status: SharedStateStatus)? {
        return (nil, .none)
      }
    
}

class FakeEventhub: EventHubProtocol{
    var runtimeEnv:ExtensionRuntimeEnv
    init(runtimeEnv:ExtensionRuntimeEnv){
        self.runtimeEnv = runtimeEnv
    }
    
    func start() {
    }
    
    func registerListener<T>(parentExtension: T.Type, type: EventType, source: EventSource, listener: @escaping EventListener) where T : Extension {
        runtimeEnv.registerListener(type: type, source: source, listener: listener)
    }
    
    func registerResponseListener<T>(parentExtension: T.Type, triggerEvent: Event, listener: @escaping EventListener) where T : Extension {
    }
    
    func dispatch(event: Event) {
    }
    
    func registerExtension(_ type: Extension.Type, completion: @escaping (EventHubError?) -> Void) {
    }
    
    func createSharedState(extensionName: String, data: [String : Any]?, event: Event?) {
    }
    
    func createPendingSharedState(extensionName: String, event: Event?) -> SharedStateResolver {
        return {data in
        }
    }
    
    func getSharedState(extensionName: String, event: Event?) -> (value: [String : Any]?, status: SharedStateStatus)? {

        return (nil, .none)
    }
    
}

class TestExtension:Extension{
    required init() {
    }
    
    var name: String = "test"
    
    var version: String = "test"
    
    func onRegistered() {
        
        
        registerListener(type: .configuration, source: .requestContent, listener: { event in
        
        })
    }
    
    func onUnregistered() {
    }
    
    
}


class SampleExtensionTests: XCTestCase {

    
    override func setUp() {
    }

    override func tearDown() {
        
    }

    func testExample() {
        //setup
        let runtimeEnv = ExtensionRuntimeEnv()
        EventHub.shared = FakeEventhub(runtimeEnv: runtimeEnv)
        let testEx = TestExtension()
        
        //test
        testEx.onRegistered()
        
        //verify
        XCTAssertEqual(1, runtimeEnv.listernerMapping.count)
        
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
