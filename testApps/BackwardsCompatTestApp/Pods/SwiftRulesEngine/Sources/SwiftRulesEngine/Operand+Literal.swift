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

extension Operand: ExpressibleByBooleanLiteral where T == Bool {
    public init(booleanLiteral value: Bool) {
        self = .some(value)
    }
}

extension Operand: ExpressibleByFloatLiteral where T == Double {
    public init(floatLiteral value: Double) {
        self = .some(value)
    }
}

extension Operand: ExpressibleByIntegerLiteral where T == Int {
    public init(integerLiteral value: Int) {
        self = .some(value)
    }
}

extension Operand: ExpressibleByNilLiteral {
    public init(nilLiteral _: ()) {
        self = .none
    }
}

extension Operand: ExpressibleByUnicodeScalarLiteral where T == String {
    public typealias ExtendedGraphemeClusterLiteralType = String
}

extension Operand: ExpressibleByExtendedGraphemeClusterLiteral where T == String {
    public typealias UnicodeScalarLiteralType = String
}

extension Operand: ExpressibleByStringLiteral where T == String {
    public init(stringLiteral value: String) {
        self = Operand<String>.some(value)
    }
}
