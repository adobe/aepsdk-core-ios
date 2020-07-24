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
@_implementationOnly import SwiftRulesEngine
import AEPServices

/// A rules engine for Launch rules
struct LaunchRulesEngine{
    let rulesEngine: RulesEngine<LaunchRule>
    let rulesDownloader: RulesDownloader
    
    init(){
        let evaluator = ConditionEvaluator.init(options: .defaultOptions)
        rulesEngine = RulesEngine(evaluator: evaluator)
        rulesDownloader = RulesDownloader(fileUnzipper: FileUnzipper())
    }
    
    /// Downloads the rules from the remote server
    /// - Parameter url: the `URL` of the remote urls
    func loadRemoteRules(from url:URL){
    }
    
    /// Reads the cached rules
    /// - Parameter url: the `URL` of the remote urls
    func loadCachedRules(for url:URL){
    }
    
    /// Evaluates all the current rules against the supplied `Event`.
    /// - Parameter event: the `Event` against which to evaluate the rules
    /// - Returns: the  processed`Event`
    func process(event: Event) -> Event{
        return event
    }
    
}
