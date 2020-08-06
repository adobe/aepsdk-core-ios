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

public struct ComparisonExpression<A, B>: Evaluable {
    let lhs: Operand<A>
    let rhs: Operand<B>
    let operationName: String

    public init(lhs: Operand<A>, operationName: String, rhs: Operand<B>) {
        self.lhs = lhs
        self.rhs = rhs
        self.operationName = operationName
    }

    public func evaluate(in context: Context) -> Result<Bool, RulesFailure> {
        let resolvedLhs = lhs(context)
        let resolvedRhs = rhs(context)
        var result: Result<Bool, RulesFailure>
        if let resolvedLhs_ = resolvedLhs, let resolvedRhs_ = resolvedRhs {
            result = context.evaluator.evaluate(operation: operationName, lhs: resolvedLhs_, rhs: resolvedRhs_)
        } else {
            result = context.evaluator.evaluate(operation: operationName, lhs: resolvedLhs, rhs: resolvedRhs)
        }
        switch result {
        case .success:
            return result
        case let .failure(error):
            return Result.failure(.innerFailure(message: "Comparison (\(lhs) \(operationName) \(rhs)) returns false", error: error))
        }
    }
}
