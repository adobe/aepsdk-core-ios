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

/// A pair of tag delimiters, such as `("{{", "}}")`.
public struct TemplateParser {
    static let DefaultTagDelimiterPair: DelimiterPair = ("{{", "}}")

    static func parse(_ templateString: String, tagDelimiterPair: DelimiterPair = TemplateParser.DefaultTagDelimiterPair) -> Result<[Segment], Error> {
        var tokens: [Segment] = []
        let currentDelimiters = ParserTagDelimiters(tagDelimiterPair)

        var state: State = .start
        var i = templateString.startIndex
        let end = templateString.endIndex

        while i < end {
            switch state {
            case .start:
                if index(i, isAt: currentDelimiters.tagDelimiterPair.0, in: templateString) {
                    state = .tag(startIndex: i)
                    i = templateString.index(i, offsetBy: currentDelimiters.tagStartLength)
                    i = templateString.index(before: i)
                } else {
                    state = .text(startIndex: i)
                }
            case let .text(startIndex):
                if index(i, isAt: currentDelimiters.tagDelimiterPair.0, in: templateString) {
                    if startIndex != i {
                        let range = startIndex ..< i
                        let token = Segment(
                            type: .text(String(templateString[range])),

                            templateString: templateString,
                            range: startIndex ..< i
                        )
                        tokens.append(token)
                    }
                    state = .tag(startIndex: i)
                    i = templateString.index(i, offsetBy: currentDelimiters.tagStartLength)
                    i = templateString.index(before: i)
                }
            case let .tag(startIndex):
                if index(i, isAt: currentDelimiters.tagDelimiterPair.1, in: templateString) {
                    let tagInitialIndex = templateString.index(startIndex, offsetBy: currentDelimiters.tagStartLength)
                    let tokenRange = startIndex ..< templateString.index(i, offsetBy: currentDelimiters.tagEndLength)
                    let content = String(templateString[tagInitialIndex ..< i])
                    let mustacheToken = MustacheToken(content)

                    let token = Segment(
                        type: .mustache(mustacheToken),
                        templateString: templateString,
                        range: tokenRange
                    )
                    tokens.append(token)

                    state = .start
                    i = templateString.index(i, offsetBy: currentDelimiters.tagEndLength)
                    i = templateString.index(before: i)
                }
            }

            i = templateString.index(after: i)
        }

        switch state {
        case .start:
            break
        case let .text(startIndex):
            let range = startIndex ..< end
            let token = Segment(
                type: .text(String(templateString[range])),

                templateString: templateString,
                range: range
            )
            tokens.append(token)
        case .tag:
            let error = MustacheError(message: "Unclosed Mustache tag")
            return .failure(error)
        }
        return .success(tokens)
    }

    private static func index(_ index: String.Index, isAt string: String?, in templateString: String) -> Bool {
        guard let string = string else {
            return false
        }
        return templateString[index...].hasPrefix(string)
    }

    // MARK: - Private

    fileprivate enum State {
        case start
        case text(startIndex: String.Index)
        case tag(startIndex: String.Index)
    }
}

/// A pair of tag delimiters, such as `("{{", "}}")`.
public typealias DelimiterPair = (String, String)

public struct ParserTagDelimiters {
    let tagDelimiterPair: DelimiterPair
    let tagStartLength: Int
    let tagEndLength: Int
    init(_ tagDelimiterPair: DelimiterPair) {
        self.tagDelimiterPair = tagDelimiterPair

        tagStartLength = tagDelimiterPair.0.distance(from: tagDelimiterPair.0.startIndex, to: tagDelimiterPair.0.endIndex)
        tagEndLength = tagDelimiterPair.1.distance(from: tagDelimiterPair.1.startIndex, to: tagDelimiterPair.1.endIndex)
    }
}
