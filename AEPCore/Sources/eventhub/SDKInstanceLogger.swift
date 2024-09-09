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

/// Tenant aware logging service.
class SDKInstanceLogger: Logger {
    private static var instanceLoggers: [SDKInstanceIdentifier: SDKInstanceLogger] = [:]
    // DispatchQueue to synchronize access to `instanceLoggers` dictionary
    private static let loggersQueue = DispatchQueue(label: "com.adobe.queue.sdkinstancelogger")
    
    private let instance: SDKInstanceIdentifier
    
    private init(instance: SDKInstanceIdentifier) {
        self.instance = instance
    }
    
    /// Get a `SDKInstanceLogger` for the given `SDKInstanceIdentifier`.
    /// - Parameter instance: the SDK instance identifier.
    /// - Returns: a `Logger` for the given `instance`.
    static func getForInstance(_ instance: SDKInstanceIdentifier) -> SDKInstanceLogger {
        loggersQueue.sync {
            if let logger = instanceLoggers[instance] {
                return logger
            } else {
                let logger = SDKInstanceLogger(instance: instance)
                instanceLoggers[instance] = logger
                return logger
            }
        }
    }

    /// Used to print more verbose information.
    /// - Parameters:
    ///   - label: the name of the label to localize message
    ///   - message: the string to be logged
    func trace(label: String, _ message: String) {
        Log.trace(label: label.instanceAwareName(for: instance), message)
    }

    /// Information provided to the debug method should contain high-level details about the data being processed
    /// - Parameters:
    ///   - label: the name of the label to localize message
    ///   - message: the string to be logged
    func debug(label: String, _ message: String) {
        Log.debug(label: label.instanceAwareName(for: instance), message)
    }

    /// Information provided to the warning method indicates that a request has been made to the SDK, but the SDK will be unable to perform the requested task
    /// - Parameters:
    ///   - label: the name of the label to localize message
    ///   - message: the string to be logged
    func warning(label: String, _ message: String) {
        Log.warning(label: label.instanceAwareName(for: instance), message)
    }

    /// Information provided to the error method indicates that there has been an unrecoverable error
    /// - Parameters:
    ///   - label: the name of the label to localize message
    ///   - message: the string to be logged
    func error(label: String, _ message: String) {
        Log.error(label: label.instanceAwareName(for: instance), message)
    }
}
