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

public struct LogicalExpression: Evaluable {
    public let operands: [Evaluable]
    public let operationName: String

    public init(operationName: String, operands: Evaluable...) {
        self.operands = operands
        self.operationName = operationName
    }

    public init(operationName: String, operands: [Evaluable]) {
        self.operands = operands
        self.operationName = operationName
    }

    public func evaluate(in context: Context) -> Result<Bool, RulesFailure> {
        let operandsResolve = operands.map { Evaluable in
            Evaluable.evaluate(in: context)
        }

        switch operationName {
        case "and":
            if operandsResolve.contains(where: { !$0.value }) {
                return Result.failure(.innerFailures(message: "`And` returns false", errors: operandsResolve.filter { !$0.value }.map { $0.error! }))
            }
            return .success(true)
        case "or":
            if operandsResolve.contains(where: { $0.value }) {
                return .success(true)
            }
            return Result.failure(.innerFailures(message: "`Or` returns false", errors: operandsResolve.filter { !$0.value }.map { $0.error ?? RulesFailure.unknown }))
        default:
            return .failure(.missingOperator(message: "Unkonwn conjunction operator"))
        }
    }
}
