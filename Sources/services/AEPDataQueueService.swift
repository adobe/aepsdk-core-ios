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

public class AEPDataQueueService: DataQueueService {
    public static let shared: DataQueueService = AEPDataQueueService()
    private let serialQueue = DispatchQueue(label: "com.adobe.marketing.mobile.dataqueueservice")
    private var threadSafeDictionary = ThreadSafeDictionary<String, DataQueue>()

    private init() {}

    public func initDataQueue(label databaseName: String) -> DataQueue? {
        if let queue = threadSafeDictionary[databaseName] {
            return queue
        } else {
            let dataQueue = AEPDataQueue(databaseName: databaseName, serialQueue: serialQueue)
            threadSafeDictionary[databaseName] = dataQueue
            return dataQueue
        }
    }

    internal func cleanCache() {
        threadSafeDictionary = ThreadSafeDictionary<String, DataQueue>()
    }
}
