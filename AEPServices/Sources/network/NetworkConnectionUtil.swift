/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

///
/// Helper class used to format the default http headers
///
public struct DefaultHeadersFormatter {

    typealias httpHeaderConstants = HttpConnectionConstants.Header
    ///
    /// Returns the default headers for connection: Accept-Language(locale), Content-Type, User-Agent
    /// - Parameters:
    ///     - locale: Active locale from platform
    ///     - contentType: The custom content type string
    /// - Returns: headers as dictionary
    ///
    public static func getHeadersFor(locale: String, contentType: String = "") -> [String: String] {
        var headers: [String: String] = [:]
        if !locale.isEmpty {
            headers[httpHeaderConstants.HTTP_HEADER_KEY_ACCEPT_LANGUAGE] = getFormattedLocale(unformattedLocale: locale)
        }

        headers[httpHeaderConstants.HTTP_HEADER_KEY_CONTENT_TYPE] = contentType.isEmpty ? httpHeaderConstants.HTTP_HEADER_CONTENT_TYPE_WWW_FORM_URLENCODED : contentType

        return headers
    }

    ///
    /// Gets the formatted locale
    /// - Parameter unformattedLocale: The unformatted locale as a string
    /// - Returns: The formatted locale as a string or nil if not able to format it.
    ///
    private static func getFormattedLocale(unformattedLocale: String) -> String? {
//        "^"                                // beginning of line
//        "([a-zA-Z]{2,3})"                      // language (required) (match group 1)
//        "(?:(?:-|_)[a-zA-Z]{3})?"           // extlang (optional)
//        "(?:(?:-|_)[a-zA-Z]{4})?"           // script (optional)
//        "(?:(?:-|_)([a-zA-Z]{2}|[0-9]{3}))?" // region (optional) (match group 2)
//        "(?:(?:\\.|-|_).*)?"                 // variant, extension, private, or anything else
//        "$"
        let pattern = #"^([a-zA-Z]{2,3})(?:(?:-|_)[a-zA-Z]{3})?(?:(?:-|_)[a-zA-Z]{4})?(?:(?:-|_)([a-zA-Z]{2}|[0-9]{3}))?(?:(?:\.|-|_).*)?$"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let localeRange = NSRange(unformattedLocale.startIndex ..< unformattedLocale.endIndex, in: unformattedLocale)
        var language: String?
        var region: String?
        regex.enumerateMatches(in: unformattedLocale, options: [], range: localeRange) { match, _, _ in
            guard let match = match else { return }
            guard let languageCaptureRange = Range(match.range(at: 1), in: unformattedLocale) else { return }
            language = String(unformattedLocale[languageCaptureRange])
            guard let regionCaptureRange = Range(match.range(at: 2), in: unformattedLocale) else { return }
            region = String(unformattedLocale[regionCaptureRange])
        }

        if let language = language {
            if let region = region {
                return language + "-" + region
            }
            return language
        }

        // Default return if no language or region is found
        return "en-US"
    }
}
