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

@dynamicCallable
public enum Operand<T> {
    case none
    case some(T)
    case token(MustacheToken)

    func dynamicallyCall(withArguments args: [Context]) -> T? {
        switch self {
        case .none:
            return nil
        case let .some(value):
            return value
        case let .token(token):

            if let result = token.resolve(in: args[0]) {
                return result as? T
            }
            return nil
        }
    }
}

extension Operand {
    public init(mustache: String) {
        let tokens = try? TemplateParser.parse(mustache).get()
        if let tokens = tokens, tokens.count > 0, case let .mustache(token) = tokens[0].type {
            self = .token(token)
        } else {
            self = .none
        }
    }
}

extension Operand: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none:
            return "<None>"
        case let .some(value):
            return "<Value:\(value)>"
        case let .token(mustache):
            return "<Token:\(mustache)>"
        }
    }
}

extension MustacheToken {
    public func resolve(in context: Context) -> Any? {
        switch self {
        case let .function(name, innerToken):
            let innerValue = innerToken.resolve(in: context)
            return context.transformer.transform(name: name, parameter: innerValue ?? "")
        case let .variable(path):
            return context.data.get(key: path)
        }
    }
}
