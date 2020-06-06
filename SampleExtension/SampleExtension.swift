//
//  SampleExtension.swift
//  SampleExtension
//
//  Created by Jiabin Geng on 6/5/20.
//  Copyright © 2020 Adobe. All rights reserved.
//

import Foundation
import AEPCore

class SampleExtension: ExtensionContext<SampleExtension>, Extension{
    required override init() {
    }
    
    
    
    let name = "SampleExtension"
    let version = "0.0.1"
    
    func receiveLifecycleRequest(event: Event) {
        // TODO
    }
    
    func receiveSharedState(event: Event) {
        
    }
    
    func onRegistered() {
        registerListener(type: .genericLifecycle, source: .requestContent, listener: receiveLifecycleRequest(event:))
        registerListener(type: .hub, source: .sharedState, listener: receiveSharedState(event:))
    }
    
    func onUnregistered() {}
    
}
