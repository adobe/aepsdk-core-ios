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

import AEPServices
import Foundation

/// An extension for `MobileCore` that provides methods to create and manage instances of the SDK.
/// This includes the ability to create named instances and retrieve the API for specific instances.
@objc
public extension MobileCore {

    /// Initializes a named instance of the SDK with the specified name.
    /// This method must be called first before calling any other API for the given instance.
    /// - Parameter name: The name for the SDK instance. The name must be valid; if it's invalid, instance creation will fail.
    @objc(initializeInstance:)
    static func initializeInstance(_ name: String) {
        guard let identifier = SDKInstanceIdentifier(id: name) else {
            Log.warning(label: LOG_TAG, "Unable to initialize as SDK instance name '\(name)' is invalid.")
            return
        }
                
        eventHubProvider.createEventHub(for: identifier)
    }
    
    /// Retrieves the `MobileCoreAPI` for the given instance name.
    /// If the API for the instance doesn't exist, a new one will be created and stored.
    /// - Parameter name: The name of the instance for which the API should be returned.
    /// - Returns: The `MobileCoreAPI` associated with the given instance name.
    ///
    /// - Note: For convenience, this method will create an `API` instance for any name, even if it hasn't been explicitly initialized
    /// or if the name is invalid. However, the API methods will fail at runtime if the name is invalid or if the instance hasn't
    /// been initialized via `create(name:)`. This allows simple usage without null checks but requires ensuring that the
    /// instance has been properly created before calling any API methods.
    @objc(apiForInstance:)
    static func api(for name: String) -> MobileCoreAPI {
        if let _ = SDKInstanceIdentifier(id: name) {
            Log.warning(label: LOG_TAG, "SDK instance name '\(name)' is invalid.")
        }
        
        // Return the API if it exists, otherwise create a new one.
        return apiQueue.sync {
            if let api = apiStore[name] {
                return api
            } else {                
                let api = MobileCoreAPI(instanceIdentifier: name, eventHubProvider: eventHubProvider)
                apiStore[name] = api
                return api
            }
        }
    }
}
