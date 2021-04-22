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

import AEPServices
import Foundation
import AEPRulesEngine

/// A rules engine for Launch rules
public extension LaunchRulesEngine {
    /// Downloads the rules from the remote server
    /// - Parameter urlString: the url of the remote rules
    func replaceRules(from urlString: String) {
        guard let url = URL(string: urlString) else {
            Log.warning(label: RulesConstants.LOG_MODULE_PREFIX, "Invalid rules url: \(urlString)")
            return
        }
        let rulesDownloader = RulesDownloader(fileUnzipper: FileUnzipper())
        rulesDownloader.loadRulesFromUrl(rulesUrl: url) { data in
            guard let data = data else {
                return
            }

            guard let rules = JSONRulesParser.parse(data) else {
                return
            }

            self.replaceRules(with: rules)
        }
    }

    /// Reads the cached rules
    /// - Parameter urlString: the url of the remote rules
    func replaceRulesWithCache(from urlString: String) {
        guard let url = URL(string: urlString) else {
            Log.warning(label: RulesConstants.LOG_MODULE_PREFIX, "Invalid rules url: \(urlString)")
            return
        }
        let rulesDownloader = RulesDownloader(fileUnzipper: FileUnzipper())
        guard let data = rulesDownloader.loadRulesFromCache(rulesUrl: url) else {
            return
        }

        guard let rules = JSONRulesParser.parse(data) else {
            return
        }
        self.replaceRules(with: rules)
    }

}
