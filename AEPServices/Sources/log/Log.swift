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

/// A Log object used to log messages for the SDK
@objc(AEPLog) public class Log: NSObject {
    /// Sets and gets the logging level of the SDK, default value is LogLevel.error
    @objc public static var logFilter: LogLevel = LogLevel.error
    private static var loggingService: Logging {
        return ServiceProvider.shared.loggingService
    }

    /// Used to print more verbose information.
    /// - Parameters:
    ///   - label: the name of the label to localize message
    ///   - message: the string to be logged
    @objc(traceWithLabel:message:)
    public static func trace(label: String, _ message: String) {
        if logFilter >= .trace {
            loggingService.log(level: .trace, label: label, message: message)
        }
    }

    /// Information provided to the debug method should contain high-level details about the data being processed
    /// - Parameters:
    ///   - label: the name of the label to localize message
    ///   - message: the string to be logged
    @objc(debugWithLabel:message:)
    public static func debug(label: String, _ message: String) {
        if logFilter >= .debug {
            loggingService.log(level: .debug, label: label, message: message)
        }
    }

    /// Information provided to the warning method indicates that a request has been made to the SDK, but the SDK will be unable to perform the requested task
    /// - Parameters:
    ///   - label: the name of the label to localize message
    ///   - message: the string to be logged
    @objc(warningWithLabel:message:)
    public static func warning(label: String, _ message: String) {
        if logFilter >= .warning {
            loggingService.log(level: .warning, label: label, message: message)
        }
    }

    /// Information provided to the error method indicates that there has been an unrecoverable error
    /// - Parameters:
    ///   - label: the name of the label to localize message
    ///   - message: the string to be logged
    @objc(errorWithLabel:message:)
    public static func error(label: String, _ message: String) {
        if logFilter >= .error {
            loggingService.log(level: .error, label: label, message: message)
        }
    }
}
