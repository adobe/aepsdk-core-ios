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
import AEPRulesEngine

class RulesEngineNativeLogging: AEPRulesEngine.Logging {
    /// Converts RulesEngine `LogLevel` to Core `LogLevel`
    /// - Parameter logLevel: a RulesEngine `LogLevel` object
    /// - Returns: a Core `LogLevel` object
    private func convert(_ logLevel: AEPRulesEngine.LogLevel) -> AEPServices.LogLevel {
        switch logLevel {
        case .error:
            return .error
        case .warning:
            return .warning
        case .debug:
            return .debug
        case .trace:
            return .trace
        @unknown default:
            return .error
        }
    }

    func log(level: AEPRulesEngine.LogLevel, label: String, message: String) {
        if Log.logFilter >= convert(level) {
            ServiceProvider.shared.loggingService.log(level: convert(level), label: label, message: message)
        }
    }
}
