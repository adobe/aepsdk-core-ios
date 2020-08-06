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

/// An enum type representing different levels of logging used by the SDK.
///
/// * _LogLevel.trace_ - This method should be used to deliver highly detailed information to the console.  Information provided to the _trace_ method is verbose and should give insight to the developer about how the SDK is processing data.  The intended audience for _trace_ logs is an Adobe SDK team member.  _trace_ logs will only be printed to the console if the developer has set a LoggingMode of VERBOSE in the SDK.
/// * _LogLevel.debug_ - This method should be used when printing high-level information to the console about the data being processed.  The intended audience for _debug_ logs is a developer integrating the SDK.  _debug_ logs will be printed to the console if the developer has set a LoggingMode of VERBOSE or DEBUG in the SDK.
/// * _LogLevel.warning_ - This method should be used to indicate that a request has been made to the SDK, but the SDK will be unable to perform the requested task.  An example of when to use _warning_ is when catching an unexpected but recoverable exception and printing its message.  The intended audience for _warning_ logs is a developer integrating the SDK.  _warning_ logs will be printed to the console if the developer has set a LoggingMode of VERBOSE, DEBUG, or WARNING in the SDK.
/// * _LogLevel.error_ - This method should be used when the SDK has determined that there is an unrecoverable error.  The intended audience for _error_ logs is a developer integrating the SDK.  _error_ logs are always enabled, and will be printed to the developer console regardless of the LoggingMode of the SDK.
///
@objc(AEPLogLevel) public enum LogLevel: Int, Comparable {
    case error = 0
    case warning = 1
    case debug = 2
    case trace = 3

    /// Compares two `LogLevel`s for order
    /// - Parameters:
    ///   - lhs: the first `LogLevel` to be compared
    ///   - rhs: the second `LogLevel` to be compared
    /// - Returns: true, only if the second `LogLevel` is more critical
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    public func toString() -> String {
        switch self {
        case .trace:
            return "TRACE"
        case .debug:
            return "DEBUG"
        case .warning:
            return "WARNING"
        case .error:
            return "ERROR"
        }
    }
}
