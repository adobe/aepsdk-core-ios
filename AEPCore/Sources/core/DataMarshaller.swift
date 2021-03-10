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

class DataMarshaller {

    /*
     Legacy Keys:
     These are used to properly grab a value from another service, or from a provider outside
     of the SDK. For our purposes, we will, if necessary, convert the legacy key into one that
     conforms with the naming convention used in for our EventData keys in V5
     */
    private static let LEGACY_PUSH_MESSAGE_ID = "adb_m_id"
    private static let LEGACY_LOCAL_NOTIFICATION_ID = "adb_m_l_id"
    private static let LEGACY_DEEPLINK_URL = "adb_deeplink"

    // generic names for the core
    private static let PUSH_MESSAGE_ID_KEY = "pushmessageid"
    private static let LOCAL_NOTIFICATION_ID_KEY = "notificationid"
    private static let DEEPLINK_KEY = "deeplink"

    init() {
    }

    /// Marshal the application context available at launch time into a generic Dictionary.
    ///
    /// - Parameter userInfo: dictionary of context data available at launch time
    /// - Returns: `Dictionary` containing the processed keys from the received user info
    static func marshalLaunchInfo(_ userInfo: [String: Any]) -> [String: Any] {
        guard !userInfo.isEmpty else {
            return userInfo
        }
        var userInfoCopy = userInfo
        DataMarshaller.replaceKey(&userInfoCopy, fromKey: DataMarshaller.LEGACY_PUSH_MESSAGE_ID, newKey: DataMarshaller.PUSH_MESSAGE_ID_KEY)
        DataMarshaller.replaceKey(&userInfoCopy, fromKey: DataMarshaller.LEGACY_LOCAL_NOTIFICATION_ID, newKey: DataMarshaller.LOCAL_NOTIFICATION_ID_KEY)
        DataMarshaller.replaceKey(&userInfoCopy, fromKey: DataMarshaller.LEGACY_DEEPLINK_URL, newKey: DataMarshaller.DEEPLINK_KEY)
        return userInfoCopy
    }

    private static func replaceKey(_ dictionary: inout [String: Any], fromKey key: String, newKey: String) {
        if let value = dictionary.removeValue(forKey: key) {
            if let stringValue = value as? String, stringValue.isEmpty {
                return
            }
            dictionary[newKey] = value
        }
    }
}
