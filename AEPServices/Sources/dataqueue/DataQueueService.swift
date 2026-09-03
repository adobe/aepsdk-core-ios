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

/// An implementation of protocol `DataQueuing`
///      - initializes `DataQueue` objects by label name
///      - caches `DataQueue` objects, then it can be retrieved later by the same label name
public class DataQueueService: DataQueuing {

    private let dbQueue = DispatchQueue(label: "com.adobe.dataQueueService.db")
    private let storeQueue = DispatchQueue(label: "com.adobe.dataQueueService.store")
    #if DEBUG
        internal var store: [String: DataQueue] = [:]
    #else
        private var store: [String: DataQueue] = [:]
    #endif

    private var configs: [String: DataQueueConfig] = [:]

    public init() {}

    public func setConfig(_ config: DataQueueConfig, forLabel label: String) {
        storeQueue.sync { configs[label] = config }
    }

    public func getDataQueue(label databaseName: String) -> DataQueue? {
        storeQueue.sync {
            if let queue = store[databaseName] {
                return queue
            }
            // Config is read at creation only, so the label's first request fixes its tuning.
            let config = configs[databaseName] ?? DataQueueConfig()
            let dataQueue = SQLiteDataQueue(databaseName: databaseName, serialQueue: dbQueue, config: config)
            store[databaseName] = dataQueue
            return dataQueue
        }
    }
}
