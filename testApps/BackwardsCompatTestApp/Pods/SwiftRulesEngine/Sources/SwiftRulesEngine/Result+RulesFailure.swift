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

extension Result where Success == Bool, Failure == RulesFailure {
    var value: Bool {
        switch self {
        case let .success(value):
            return value
        default:
            return false
        }
    }

    var error: RulesFailure? {
        switch self {
        case let .failure(error):
            return error
        default:
            return nil
        }
    }
}

extension RulesFailure: CustomStringConvertible {
    public var description: String {
        getLines().joined(separator: "\n")
    }

    func getLines() -> [String] {
        switch self {
        case let .conditionNotMatched(message):
            return [message]
        case let .missingOperator(message):
            return [message]
        case let .innerFailure(message, innerFailure):
            return [message] + innerFailure.getLines().map { "   ->" + $0 }
        case let .innerFailures(message, innerFailures):
            return [message] + innerFailures.reduce([] as [String]) { current, rulesFailure -> [String] in
                current + rulesFailure.getLines()
            }.map { "   " + $0 }
        default:
            return ["unknown failure"]
        }
    }
}
