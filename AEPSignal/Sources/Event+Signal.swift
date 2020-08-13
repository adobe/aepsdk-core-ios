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

import AEPCore
import Foundation

extension Event {
    // MARK: - Consequence Types

    var isPostback: Bool {
        return consequenceType == SignalConstants.ConsequenceTypes.POSTBACK
    }

    var isOpenUrl: Bool {
        return consequenceType == SignalConstants.ConsequenceTypes.OPEN_URL
    }

    var isCollectPii: Bool {
        return consequenceType == SignalConstants.ConsequenceTypes.PII
    }

    // MARK: - Postback/PII Consequences

    var contentType: String? {
        return details?[SignalConstants.EventDataKeys.CONTENT_TYPE] as? String
    }

    var templateUrl: String? {
        return details?[SignalConstants.EventDataKeys.TEMPLATE_URL] as? String
    }

    var templateBody: String? {
        return details?[SignalConstants.EventDataKeys.TEMPLATE_BODY] as? String
    }

    var timeout: TimeInterval? {
        if let intervalDouble = details?[SignalConstants.EventDataKeys.TIMEOUT] as? Double {
            return TimeInterval(intervalDouble)
        } else if let intervalInt = details?[SignalConstants.EventDataKeys.TIMEOUT] as? Int {
            return TimeInterval(intervalInt)
        }
        return nil
    }

    // MARK: - Open URL Consequences

    var urlToOpen: String? {
        return details?[SignalConstants.EventDataKeys.URL] as? String
    }

    // MARK: - Consequence EventData Processing

    private var consequence: [String: Any]? {
        return data?[SignalConstants.EventDataKeys.TRIGGERED_CONSEQUENCE] as? [String: Any]
    }

    private var consequenceId: String? {
        return consequence?[SignalConstants.EventDataKeys.ID] as? String
    }

    private var consequenceType: String? {
        return consequence?[SignalConstants.EventDataKeys.TYPE] as? String
    }

    private var details: [String: Any]? {
        return consequence?[SignalConstants.EventDataKeys.DETAIL] as? [String: Any]
    }
}
