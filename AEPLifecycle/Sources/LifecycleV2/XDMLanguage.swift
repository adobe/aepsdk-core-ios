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

import AEPServices
import Foundation

/// Represents the language of the environment to represent the user's linguistic, geographical, or cultural preferences for data presentation.
struct XDMLanguage: Encodable {
    static let languageRegex =  "^(((([A-Za-z]{2,3}(-([A-Za-z]{3}(-[A-Za-z]{3}){0,2}))?)|[A-Za-z]{4}|[A-Za-z]{5,8})(-([A-Za-z]{4}))?(-([A-Za-z]{2}|[0-9]{3}))?(-([A-Za-z0-9]{5,8}|[0-9][A-Za-z0-9]{3}))*(-([0-9A-WY-Za-wy-z](-[A-Za-z0-9]{2,8})+))*(-(x(-[A-Za-z0-9]{1,8})+))?)|(x(-[A-Za-z0-9]{1,8})+)|((en-GB-oed|i-ami|i-bnn|i-default|i-enochian|i-hak|i-klingon|i-lux|i-mingo|i-navajo|i-pwn|i-tao|i-tay|i-tsu|sgn-BE-FR|sgn-BE-NL|sgn-CH-DE)|(art-lojban|cel-gaulish|no-bok|no-nyn|zh-guoyu|zh-hakka|zh-min|zh-min-nan|zh-xiang)))$"

    let language: String?

    init(language: String?) {
        guard let language = language else {
            self.language = nil
            return
        }

        if XDMLanguage.isValidLanguageTag(tag: language) {
            self.language = language
        } else {
            self.language = nil
            Log.warning(label: LifecycleConstants.LOG_TAG, "Language tag \(language) failed validation and will be dropped. Values for XDM field 'environment._dc.language' must conform to BCP 47.")
        }
    }

    /// Validate the language tag is formatted per the XDM Environment Schema pattern.
    /// - Parameter tag: the language tag to validate
    /// - Returns: true if the language tag matches the pattern
    private static func isValidLanguageTag(tag: String) -> Bool {
        return tag.range(of: languageRegex, options: .regularExpression) != nil
    }
}
