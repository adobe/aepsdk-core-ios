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

public class Template {
    let tokens: [Segment]
    public init(templateString: String) {
        let result = TemplateParser.parse(templateString)
        tokens = (try? result.get()) ?? []
    }

    public init(templateString: String, tagDelimiterPair: DelimiterPair) {
        let result = TemplateParser.parse(templateString, tagDelimiterPair: tagDelimiterPair)
        tokens = (try? result.get()) ?? []
    }

    public func render(data: Traversable, transformers: Transforming) -> String {
        tokens.map { token in
            switch token.type {
            case let .text(content):
                return content
            case let .mustache(mustache):
                let value = mustache.resolve(in: transformers, data: data)
                if let value = value {
                    return String(describing: value)
                }
                return ""
            }
        }.joined()
    }
}
