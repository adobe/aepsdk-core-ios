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

/// A Log object used to log messages for the SDK
@objc(AEPLog) public class Log: NSObject {
    /// Sets and gets the logging level of the SDK, default value is LogLevel.error
    @objc public static var logFilter: LogLevel = LogLevel.error
    private static var loggingService: Logging {
        return ServiceProvider.shared.loggingService
    }

    // MARK: - Trace

    /// Used to print more verbose information.
    /// - Parameters:
    ///   - label: the name of the label to localize message
    ///   - message: the string to be logged
    @objc(traceWithLabel:message:)
    public static func trace(label: String, _ message: String) {
        emit(.trace, label: label, template: message, data: nil)
    }

    /// Logs verbose information with one or more dictionaries embedded via `{key}` placeholders.
    /// The dictionaries are converted to JSON only after the level check passes, so pass heavy
    /// data here instead of interpolating `PrettyDictionary.prettify(...)` into the message.
    /// - Parameters:
    ///   - label: the name of the label to localize message
    ///   - template: message text with `{key}` placeholders
    ///   - data: dictionaries keyed by placeholder name; serialized lazily
    @objc(traceWithLabel:template:data:)
    public static func trace(label: String, template: String, data: [String: [String: Any]]) {
        emit(.trace, label: label, template: template, data: data)
    }

    // MARK: - Debug

    /// Information provided to the debug method should contain high-level details about the data being processed
    /// - Parameters:
    ///   - label: the name of the label to localize message
    ///   - message: the string to be logged
    @objc(debugWithLabel:message:)
    public static func debug(label: String, _ message: String) {
        emit(.debug, label: label, template: message, data: nil)
    }

    /// Logs debug information with dictionaries embedded via `{key}`. See `trace(label:template:data:)`.
    @objc(debugWithLabel:template:data:)
    public static func debug(label: String, template: String, data: [String: [String: Any]]) {
        emit(.debug, label: label, template: template, data: data)
    }

    // MARK: - Warning

    /// Information provided to the warning method indicates that a request has been made to the SDK, but the SDK will be unable to perform the requested task
    /// - Parameters:
    ///   - label: the name of the label to localize message
    ///   - message: the string to be logged
    @objc(warningWithLabel:message:)
    public static func warning(label: String, _ message: String) {
        emit(.warning, label: label, template: message, data: nil)
    }

    /// Logs a warning with dictionaries embedded via `{key}`. See `trace(label:template:data:)`.
    @objc(warningWithLabel:template:data:)
    public static func warning(label: String, template: String, data: [String: [String: Any]]) {
        emit(.warning, label: label, template: template, data: data)
    }

    // MARK: - Error

    /// Information provided to the error method indicates that there has been an unrecoverable error
    /// - Parameters:
    ///   - label: the name of the label to localize message
    ///   - message: the string to be logged
    @objc(errorWithLabel:message:)
    public static func error(label: String, _ message: String) {
        emit(.error, label: label, template: message, data: nil)
    }

    /// Logs an error with dictionaries embedded via `{key}`. See `trace(label:template:data:)`.
    @objc(errorWithLabel:template:data:)
    public static func error(label: String, template: String, data: [String: [String: Any]]) {
        emit(.error, label: label, template: template, data: data)
    }

    // MARK: - Internal

    /// Single gate for all levels: build the message only when the level is enabled.
    private static func emit(_ level: LogLevel, label: String, template: String, data: [String: [String: Any?]?]?) {
        guard logFilter >= level else { return }
        let message = data.map { interpolate(template, $0) } ?? template
        loggingService.log(level: level, label: label, message: message)
    }

    /// Replaces `{key}` placeholders with the prettified JSON of the matching dictionary.
    ///
    /// Done in a single left-to-right pass so the JSON we insert (which itself contains `{ } %`)
    /// is never re-scanned, and unknown or malformed tokens fall through as plain text. Uses
    /// `String.Index` throughout to stay correct for multi-byte characters.
    static func interpolate(_ template: String, _ data: [String: [String: Any?]?]) -> String {
        guard !data.isEmpty else { return template }
        var result = ""
        result.reserveCapacity(template.count)
        var index = template.startIndex
        while index < template.endIndex {
            if template[index] == "{",
               let closing = template[index...].firstIndex(of: "}") {
                let key = String(template[template.index(after: index)..<closing])
                if let value = data[key] {
                    result += PrettyDictionary.prettify(value)
                    index = template.index(after: closing)
                    continue
                }
            }
            result.append(template[index])
            index = template.index(after: index)
        }
        return result
    }
}
