//
//  SampleExtensionTests.swift
//  SampleExtensionTests
//
//  Created by Jiabin Geng on 6/5/20.
//  Copyright © 2020 Adobe. All rights reserved.
//

import XCTest
@testable import SampleExtension
@testable import AEPCore


class SampleExtensionTestable: SampleExtension{


    override func registerListener(type: EventType, source: EventSource, listener: @escaping EventListener) {
        ExtensionRuntimeEnv.shared.registerListener(type: type, source: source, listener: listener)
    }

     override func dispatch(event: Event) {
        ExtensionRuntimeEnv.shared.dispatch(event:event)
    }

     override func createSharedState(data: [String: Any], event: Event?) {
        ExtensionRuntimeEnv.shared.createSharedState(extensionName: name, data: data, event: event)
    }

     override func createPendingSharedState(event: Event?) -> SharedStateResolver {
        ExtensionRuntimeEnv.shared.createPendingSharedState(extensionName: name, event: event)
    }

     override func getSharedState(extensionName: String, event: Event?) -> (value: [String: Any]?, status: SharedStateStatus)? {
        ExtensionRuntimeEnv.shared.getSharedState(extensionName: extensionName, event: event)
    }

    func simulateEvent(type: EventType, source: EventSource, event: Event){
        ExtensionRuntimeEnv.shared.simulateEvent(type: type, source: source, event: event)
    }
}




class SampleExtensionTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

    func testExtensionRegistration() {
        let sampleExtension = SampleExtensionTestable()
        sampleExtension.onRegistered()
        
        XCTAssertEqual(2, ExtensionRuntimeEnv.shared.listernerMapping.count)
        
        
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
