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
    public let processor: HitProcessing
    let dataQueue: DataQueue

    private static let DEFAULT_RETRY_INTERVAL = TimeInterval(30)
    private var suspended = true
    private let queue = DispatchQueue(label: "com.adobe.mobile.persistenthitqueue")
    private var currentBatchSize = 0
    private var batching = false

    /// Creates a new `HitQueue` with the underlying `DataQueue` which is used to persist hits
    /// - Parameter dataQueue: a `DataQueue` used to persist hits
    /// - Parameter processor: a `HitProcessing` used to process hits
    public init(dataQueue: DataQueue, processor: HitProcessing) {
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
        batching = self.processor.batchLimit > 0
        processNextHit()
    }

    // Processes the queued hits ignoring the batchLimit
    public func forceProcessing() {
        queue.async { self.suspended = false }
        processNextHit(ignoreBatchLimit: true)
    }

    public func suspend() {
        queue.async { self.suspended = true }
    }

    public func clear() {
        _ = dataQueue.clear()
        self.currentBatchSize = 0
    }

    public func count() -> Int {
        return dataQueue.count()
    }

    public func close() {
        suspend()
        dataQueue.close()
    }

    /// A recursive function for processing hits, it will continue processing all the hits until none are left in the data queue
    /// - Parameter ignoreBatchLimit: a `Bool` flag to determine batching hits
    private func processNextHit(ignoreBatchLimit: Bool = false) {
        queue.async {
            if self.batching && !ignoreBatchLimit {
                // check if number of queued hits > batchLimit and currently we are not processing a batch of hits
                if self.dataQueue.count() >= self.processor.batchLimit && self.currentBatchSize == 0 {
                    // There is no batch being processed currently so set the currentBatchSize to batchLimit
                    self.currentBatchSize = self.processor.batchLimit
                }

                // Only process hits if number of queued hits >= batchLimit
                guard self.currentBatchSize > 0 else { return }
            }

            guard !self.suspended else { return }
            guard let hit = self.dataQueue.peek() else { return } // nothing left in the queue, stop processing

            let semaphore = DispatchSemaphore(value: 0)
            self.processor.processHit(entity: hit, completion: { [weak self] success in
                if success {
                    // successful processing of hit, remove it from the queue, move to next hit
                    _ = self?.dataQueue.remove()

                    if self?.batching ?? false {
                        // Successfully processed hit, so update the currentBatchSize to reflect remaining number of hits to be processed
                        self?.currentBatchSize -= 1
                    }

                    self?.processNextHit(ignoreBatchLimit: ignoreBatchLimit)
                } else {
                    // processing hit failed, leave it in the queue, retry after the retry interval
                    self?.queue.asyncAfter(deadline: .now() + (self?.processor.retryInterval(for: hit) ?? PersistentHitQueue.DEFAULT_RETRY_INTERVAL)) {
                        self?.processNextHit(ignoreBatchLimit: ignoreBatchLimit)
                    }
                }

                semaphore.signal()
            })
            semaphore.wait()
        }
    }
}
