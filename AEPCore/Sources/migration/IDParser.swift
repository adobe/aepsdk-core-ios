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

/// Parses visitor id strings into dictionary representations
struct IDParser: IDParsing {

    private let CID_DELIMITER = "%01"

    func convertStringToIds(idString: String?) -> [[String: Any]] {
        guard let idString = idString, !idString.isEmpty else { return [] }

        let customerIdComponentsArray = idString.components(separatedBy: "&")
        var ids: [[String: Any]] = []

        for idInfo in customerIdComponentsArray where !idInfo.isEmpty {
            // AMSDK-3686
            // equals signs are causing a crash when we load stored values from defaults
            // to fix, we will look for the first equals sign and create the array based off of that
            guard let firstEqualsIndex = idInfo.range(of: "=") else {
                continue
            }

            let currentCustomerIdOrigin = idInfo[...firstEqualsIndex.upperBound]
            let currentCustomerIdValue = idInfo[firstEqualsIndex.upperBound...]

            // make sure we have valid values
            if currentCustomerIdOrigin.isEmpty || currentCustomerIdValue.isEmpty {
                continue
            }

            let idValueComponents = currentCustomerIdValue.components(separatedBy: CID_DELIMITER)

            // must have 3 entries and id not empty
            if idValueComponents.count != 3 || idValueComponents[1].isEmpty {
                continue
            }

            let IdDict = ["origin": currentCustomerIdOrigin, "type": idValueComponents[0], "id": idValueComponents[1], "authenticationState": Int(idValueComponents[2]) ?? 0] as [String: Any]
            ids.append(IdDict)
        }

        return ids
    }
}
