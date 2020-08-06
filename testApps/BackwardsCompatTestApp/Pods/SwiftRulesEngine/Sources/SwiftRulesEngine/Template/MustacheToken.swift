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
public indirect enum MustacheToken {
    /// text
    case variable(text: String)

    /// {{ content }}
    case function(content: String, inner: MustacheToken)

    public init(_ tokenString: String) {
        if let range = tokenString.range(of: #"\((.*\))+"#, options: .regularExpression) {
            let variable = String(tokenString[tokenString.index(after: range.lowerBound) ..< tokenString.index(before: range.upperBound)]).trimmingCharacters(in: .whitespacesAndNewlines)
            let funtionName = String(tokenString[tokenString.startIndex ... tokenString.index(before: range.lowerBound)]).trimmingCharacters(in: .whitespacesAndNewlines)
            self = .function(content: funtionName, inner: .variable(text: variable))
        } else {
            self = .variable(text: tokenString)
        }
    }

    public func resolve(in transformer: Transforming, data: Traversable) -> Any? {
        switch self {
        case let .function(name, innerToken):
            let innerValue = innerToken.resolve(in: transformer, data: data)
            return transformer.transform(name: name, parameter: innerValue ?? "")
        case let .variable(name):
            return data.get(key: name)
        }
    }
}
