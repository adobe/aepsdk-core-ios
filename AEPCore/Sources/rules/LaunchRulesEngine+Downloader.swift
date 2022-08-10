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
        rulesDownloader.loadRulesFromUrl(rulesUrl: url) { result in
            switch result {
            case .success(let data):
                guard let rules = JSONRulesParser.parse(data) else {
                    Log.debug(label: RulesConstants.LOG_MODULE_PREFIX, "Unable to parse rules for data from URL: \(urlString)")
                    return
                }
                self.replaceRules(with: rules)
            case .failure(let error):
                switch error {
                case .notModified:
                    Log.trace(label: RulesConstants.LOG_MODULE_PREFIX, "Rules were not modified, not loading rules from url: \(urlString)")
                default:
                    Log.debug(label: RulesConstants.LOG_MODULE_PREFIX, "Failed to load rules from url: \(urlString), with error: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Reads the cached rules
    /// - Parameter urlString: the url of the remote rules
    func replaceRulesWithCache(from urlString: String) -> Bool {
        guard let url = URL(string: urlString) else {
            Log.warning(label: RulesConstants.LOG_MODULE_PREFIX, "Invalid rules url: \(urlString)")
            return false
        }
        let rulesDownloader = RulesDownloader(fileUnzipper: FileUnzipper())
        guard let data = rulesDownloader.loadRulesFromCache(rulesUrl: url), let rules = JSONRulesParser.parse(data, runtime: extensionRuntime) else {
            Log.debug(label: RulesConstants.LOG_MODULE_PREFIX, "Failed to load cached rules for url: \(urlString)")
            return false
        }

        Log.debug(label: RulesConstants.LOG_MODULE_PREFIX, "Successfully loaded rules from cache")
        self.replaceRules(with: rules)
        return true
    }

    /// Reads the manifest for bundled rules and replaces rules with bundled rules if found
    func replaceRulesWithManifest(from url: URL) {
        let rulesDownloader = RulesDownloader(fileUnzipper: FileUnzipper())
        switch rulesDownloader.loadRulesFromManifest(for: url) {
        case .success(let data):
            guard let rules = JSONRulesParser.parse(data) else {
                Log.debug(label: RulesConstants.LOG_MODULE_PREFIX, "Unable to parse rules for data from manifest")
                return
            }
            Log.debug(label: RulesConstants.LOG_MODULE_PREFIX, "Successfully loaded rules from manifest")
            self.replaceRules(with: rules)
        case .failure(let error):
            Log.debug(label: RulesConstants.LOG_MODULE_PREFIX, "Failed to load rules from manifest, with error: \(error.localizedDescription)")
        }
    }
}
