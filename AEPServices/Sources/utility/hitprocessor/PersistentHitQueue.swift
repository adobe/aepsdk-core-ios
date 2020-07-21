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

/// Provides functionality for asynchronous processing of hits in a synchronous manner while providing the ability to retry hits
public class PersistentHitQueue: HitQueuing {
    public let processor: HitProcessable
    let dataQueue: DataQueue
    
    private static let DEFAULT_RETRY_INTERVAL = TimeInterval(30)
    private var suspended = true
    private let queue = DispatchQueue(label: "com.adobe.mobile.persistenthitqueue")
    
    /// Creates a new `HitQueue` with the underlying `DataQueue` which is used to persist hits
    /// - Parameter dataQueue: a `DataQueue` used to persist hits
    /// - Parameter processor: a `HitProcessable` used to process hits
    public init(dataQueue: DataQueue, processor: HitProcessable) {
        self.dataQueue = dataQueue
        self.processor = processor
    }
    
    @discardableResult
    public func queue(entity: DataEntity) -> Bool {
        let result = dataQueue.add(dataEntity: entity)
        processNextHit()
        return result
    }

    public func beginProcessing() {
        queue.async { self.suspended = false }
        processNextHit()
    }

    public func suspend() {
        queue.async { self.suspended = true }
    }

    public func clear() {
        let _ = dataQueue.clear()
    }
    
    /// A recursive function for processing hits, it will continue processing all the hits until none are left in the data queue
    private func processNextHit() {
        queue.async {
            guard !self.suspended else { return }
            guard let hit = self.dataQueue.peek() else { return } // nothing let in the queue, stop processing
            
            self.processor.processHit(entity: hit, completion: { [weak self] (success) in
                if success {
                    // successful processing of hit, remove it from the queue, move to next hit
                    let _ = self?.dataQueue.remove()
                    self?.processNextHit()
                } else {
                    // processing hit failed, leave it in the queue, retry after the retry interval
                    self?.queue.asyncAfter(deadline: .now() + (self?.processor.retryInterval ?? PersistentHitQueue.DEFAULT_RETRY_INTERVAL)) {
                        self?.processNextHit()
                    }
                }
            })
        }
    }
}
