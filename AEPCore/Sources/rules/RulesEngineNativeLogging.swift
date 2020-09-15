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

import AEPServices
import Foundation
import os.log
@_implementationOnly import SwiftRulesEngine

class RulesEngineNativeLogging: RulesEngineLogging {
    /// Converts `RulesEngineLogLevel` to Core `LogLevel`
    /// - Parameter logLevel: a `RulesEngineLogLevel` object
    /// - Returns: a `LogLevel` object
    private func convert(_ logLevel: RulesEngineLogLevel) -> LogLevel {
        switch logLevel {
        case .error:
            return .error
        case .warning:
            return .warning
        case .debug:
            return .debug
        case .trace:
            return .trace
        }
    }

    func log(level: RulesEngineLogLevel, label: String, message: String) {
        if Log.logFilter >= convert(level) {
            ServiceProvider.shared.loggingService.log(level: convert(level), label: label, message: message)
        }
    }
}
