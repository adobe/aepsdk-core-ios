/*
 Copyright 2024 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

class EventHubProvider {
    
    private let dispatchQueue = DispatchQueue(label: "com.adobe.eventHubProvider")
    private var eventHubs: [SDKInstanceIdentifier: EventHub] = [
        .default: EventHub(identifier: .default)
    ]

    // Creates an EventHub instance for the given identifier if it does not already exist.
    func createEventHub(for identifier: SDKInstanceIdentifier) {
        dispatchQueue.sync {
            guard eventHubs[identifier] == nil else { return }
            eventHubs[identifier] = EventHub(identifier: identifier)
        }
    }

    // Retrieves the EventHub instance for the given identifier.
    func getEventHub(for identifier: SDKInstanceIdentifier) -> EventHub? {
        dispatchQueue.sync {
            return eventHubs[identifier]
        }
    }
}
