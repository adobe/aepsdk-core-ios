/*
 Copyright 2026 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation
@testable import AEPServices
import XCTest

/// Captures every emitted log so tests can assert what actually reached the logging service.
private class CapturingLoggingService: Logging {
    var messages: [(level: LogLevel, label: String, message: String)] = []
    func log(level: LogLevel, label: String, message: String) {
        messages.append((level, label, message))
    }
}

class LogTests: XCTestCase {

    private var capture: CapturingLoggingService!
    private var originalFilter: LogLevel!

    override func setUp() {
        capture = CapturingLoggingService()
        originalFilter = Log.logFilter
        ServiceProvider.shared.loggingService = capture
        _ = ServiceProvider.shared.loggingService // force the async setter to apply before tests run
    }

    override func tearDown() {
        Log.logFilter = originalFilter
        ServiceProvider.shared.reset()
    }

    // MARK: - interpolate: substitution

    func testInterpolate_noPlaceholders_returnsTemplate() {
        XCTAssertEqual(Log.interpolate("plain message", ["k": ["a": 1]]), "plain message")
    }

    func testInterpolate_emptyData_returnsTemplate() {
        XCTAssertEqual(Log.interpolate("has {k} token", [:]), "has {k} token")
    }

    func testInterpolate_singleKey_substituted() {
        let from: [String: Any?] = ["a": 1]
        XCTAssertEqual(Log.interpolate("x {from} y", ["from": from]),
                       "x \(PrettyDictionary.prettify(from)) y")
    }

    func testInterpolate_twoInterleavedKeys() {
        let from: [String: Any?] = ["a": 1]
        let to: [String: Any?] = ["b": 2]
        XCTAssertEqual(Log.interpolate("data: {from} to {to}\n", ["from": from, "to": to]),
                       "data: \(PrettyDictionary.prettify(from)) to \(PrettyDictionary.prettify(to))\n")
    }

    func testInterpolate_repeatedKey_substitutedEachTime() {
        let k: [String: Any?] = ["n": 1]
        let pretty = PrettyDictionary.prettify(k)
        XCTAssertEqual(Log.interpolate("{k}+{k}", ["k": k]), "\(pretty)+\(pretty)")
    }

    func testInterpolate_adjacentPlaceholders() {
        let a: [String: Any?] = ["a": 1]
        let b: [String: Any?] = ["b": 2]
        XCTAssertEqual(Log.interpolate("{a}{b}", ["a": a, "b": b]),
                       "\(PrettyDictionary.prettify(a))\(PrettyDictionary.prettify(b))")
    }

    func testInterpolate_placeholderAtStart() {
        let k: [String: Any?] = ["a": 1]
        XCTAssertEqual(Log.interpolate("{k} end", ["k": k]), "\(PrettyDictionary.prettify(k)) end")
    }

    func testInterpolate_placeholderAtEnd() {
        let k: [String: Any?] = ["a": 1]
        XCTAssertEqual(Log.interpolate("start {k}", ["k": k]), "start \(PrettyDictionary.prettify(k))")
    }

    func testInterpolate_nestedDictValue() {
        let k: [String: Any?] = ["x": ["y": 1]]
        XCTAssertEqual(Log.interpolate("{k}", ["k": k]), PrettyDictionary.prettify(k))
    }

    // MARK: - interpolate: fall-through / literals

    func testInterpolate_unknownKey_staysLiteral() {
        XCTAssertEqual(Log.interpolate("x {missing} y", ["from": ["a": 1]]), "x {missing} y")
    }

    func testInterpolate_partialKey_doesNotMatch() {
        XCTAssertEqual(Log.interpolate("{fromList}", ["from": ["a": 1]]), "{fromList}")
    }

    func testInterpolate_keyIsCaseSensitive() {
        XCTAssertEqual(Log.interpolate("{Key}", ["key": ["a": 1]]), "{Key}")
    }

    func testInterpolate_strayOpenBrace_staysLiteral() {
        XCTAssertEqual(Log.interpolate("a { b", ["from": ["a": 1]]), "a { b")
    }

    func testInterpolate_strayCloseBrace_staysLiteral() {
        XCTAssertEqual(Log.interpolate("a } b", ["from": ["a": 1]]), "a } b")
    }

    func testInterpolate_emptyPlaceholder_staysLiteral() {
        XCTAssertEqual(Log.interpolate("a {} b", ["from": ["a": 1]]), "a {} b")
    }

    func testInterpolate_jsonLikeBracesWithNoKey_unchanged() {
        XCTAssertEqual(Log.interpolate("{\"a\":1}", ["from": ["a": 1]]), "{\"a\":1}")
    }

    // MARK: - interpolate: safety

    func testInterpolate_insertedContentIsNotReScanned() {
        // The value prettifies to text that contains "{b}"; "b" is also a key. A correct single
        // pass must NOT substitute inside content it just inserted.
        let from: [String: Any?] = ["x": "{b}"]
        XCTAssertEqual(Log.interpolate("{from}", ["from": from, "b": ["z": 9]]),
                       PrettyDictionary.prettify(from))
    }

    func testInterpolate_nilValue_rendersEmpty() {
        let data: [String: [String: Any?]?] = ["k": nil]
        XCTAssertEqual(Log.interpolate("[{k}]", data), "[]")
    }

    func testInterpolate_unicodePreserved() {
        let k: [String: Any?] = ["a": 1]
        XCTAssertEqual(Log.interpolate("start {k} end", ["k": k]),
                       "start \(PrettyDictionary.prettify(k)) end")
    }

    func testInterpolate_newlinesPreserved() {
        let k: [String: Any?] = ["a": 1]
        XCTAssertEqual(Log.interpolate("\n{k}\n", ["k": k]), "\n\(PrettyDictionary.prettify(k))\n")
    }

    // MARK: - level gating (the actual fix)

    func testTrace_belowFilter_doesNothing() {
        Log.logFilter = .error
        Log.trace(label: "t", template: "data {k}", data: ["k": ["a": 1]])
        XCTAssertTrue(capture.messages.isEmpty)
    }

    func testTrace_atFilter_logsInterpolatedMessage() {
        Log.logFilter = .trace
        let k: [String: Any] = ["a": 1]
        Log.trace(label: "t", template: "data {k}", data: ["k": k])
        XCTAssertEqual(capture.messages.count, 1)
        XCTAssertEqual(capture.messages.first?.message, "data \(PrettyDictionary.prettify(k))")
    }

    func testError_alwaysLogs() {
        Log.logFilter = .error
        Log.error(label: "t", template: "boom {k}", data: ["k": ["a": 1]])
        XCTAssertEqual(capture.messages.count, 1)
        XCTAssertEqual(capture.messages.first?.level, .error)
    }

    func testMessageVariant_withoutData_logsPlainlyWithoutInterpolation() {
        Log.logFilter = .debug
        Log.debug(label: "t", "raw {k} stays")
        XCTAssertEqual(capture.messages.first?.message, "raw {k} stays")
    }
}
