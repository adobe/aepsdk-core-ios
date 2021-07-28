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

@testable import AEPServices
import AEPServicesMocks
import XCTest

class PersistentHitQueueTests: XCTestCase {
    var hitQueue: PersistentHitQueue!
    var hitProcessor: HitProcessing!
    var processedHits: [DataEntity] {
        guard let mockProcessor = hitProcessor as? MockHitProcessor else { return [] }
        return mockProcessor.processedHits.shallowCopy
    }

    override func setUp() {
        hitProcessor = MockHitProcessor()
        hitQueue = PersistentHitQueue(dataQueue: MockDataQueue(), processor: hitProcessor)
    }

    /// Tests that when the queue is in a suspended state that we store the hit in the data queue and do not invoke the processor
    func testDoesntProcessByDefault() {
        // setup
        let entity = DataEntity(uniqueIdentifier: UUID().uuidString, timestamp: Date(), data: nil)

        // test
        let result = hitQueue.queue(entity: entity)

        // verify
        XCTAssertEqual(hitQueue.dataQueue.peek(), entity) // hit should be in persistent queue
        XCTAssertTrue(processedHits.isEmpty) // mock hit processor should have never been invoked with the data entity
        XCTAssertTrue(result) // queuing hit should be successful
    }

    /// Tests that when the queue is in a suspended state that we store the hit in the data queue and do not invoke the processor
    func testClearQueue() {
        // setup
        let entity = DataEntity(uniqueIdentifier: UUID().uuidString, timestamp: Date(), data: nil)

        // test
        let result = hitQueue.queue(entity: entity)
        hitQueue.clear()

        // verify
        XCTAssertNil(hitQueue.dataQueue.peek()) // hit should no longer be in the queue
        XCTAssertTrue(processedHits.isEmpty) // mock hit processor should have never been invoked with the data entity
        XCTAssertTrue(result) // queuing hit should be successful
    }

    /// Tests that when the queue is not in a suspended state that the hit processor is invoked with the hit
    func testProcessesHit() {
        // setup
        let entity = DataEntity(uniqueIdentifier: UUID().uuidString, timestamp: Date(), data: nil)

        // test
        let result = hitQueue.queue(entity: entity)
        hitQueue.beginProcessing()
        sleep(1)

        // verify
        XCTAssertNil(hitQueue.dataQueue.peek()) // hit should no longer be in the queue as its been processed
        XCTAssertEqual(processedHits.first, entity) // mock hit processor should have been invoked with the data entity
        XCTAssertTrue(result) // queuing hit should be successful
    }

    /// Tests that multiple hits are processed and the data queue is empty
    func testProcessesHits() {
        // setup
        let entity = DataEntity(uniqueIdentifier: UUID().uuidString, timestamp: Date(), data: nil)
        let entity1 = DataEntity(uniqueIdentifier: UUID().uuidString, timestamp: Date(), data: nil)

        // test
        let result = hitQueue.queue(entity: entity)
        let result1 = hitQueue.queue(entity: entity1)
        hitQueue.beginProcessing()
        sleep(1)

        // verify
        XCTAssertNil(hitQueue.dataQueue.peek()) // hit should no longer be in the queue as its been processed
        XCTAssertEqual(processedHits.first, entity) // mock hit processor should have been invoked with the data entity
        XCTAssertEqual(processedHits.last, entity1) // mock hit processor should have been invoked with the data entity
        XCTAssertTrue(result) // queuing hit should be successful
        XCTAssertTrue(result1) // queuing hit should be successful
    }

    /// Tests that many hits are processed and the data queue is empty
    func testProcessesHitsMany() {
        // setup
        hitQueue.beginProcessing()

        // test
        for _ in 0 ..< 100 {
            hitQueue.queue(entity: DataEntity(uniqueIdentifier: UUID().uuidString, timestamp: Date(), data: nil))
        }

        sleep(1)

        // verify
        XCTAssertNil(hitQueue.dataQueue.peek()) // hit should no longer be in the queue as its been processed
        XCTAssertEqual(100, processedHits.count) // all 100 hits should have been processed
    }

    /// Tests that not all hits are processed when we suspend the queue
    func testProcessesHitsManyWithSuspend() {
        // test
        for _ in 0 ..< 100 {
            hitQueue.queue(entity: DataEntity(uniqueIdentifier: UUID().uuidString, timestamp: Date(), data: nil))
        }

        hitQueue.suspend()
        sleep(1)

        // verify
        XCTAssertNotNil(hitQueue.dataQueue.peek()) // some hits should still be in the queue
        XCTAssertNotEqual(100, processedHits.count) // we should have not processed all 100 hits by the time we have suspended
    }

    /// Tests that not all hits are processed when we suspend the queue, but then when we resume processing the remaining hits are processed
    func testProcessesHitsManyWithSuspendThenResume() {
        // test
        for _ in 0 ..< 100 {
            hitQueue.queue(entity: DataEntity(uniqueIdentifier: UUID().uuidString, timestamp: Date(), data: nil))
        }

        hitQueue.suspend()
        sleep(1)

        // verify pt. 1
        XCTAssertNotNil(hitQueue.dataQueue.peek()) // some hits should still be in the queue
        XCTAssertNotEqual(100, processedHits.count) // we should have not processed all 100 hits by the time we have suspended

        hitQueue.beginProcessing()
        sleep(1)

        // verify pt. 2
        XCTAssertNil(hitQueue.dataQueue.peek()) // hit should no longer be in the queue as its been processed
        XCTAssertEqual(100, processedHits.count) // now all hits should have been sent to the hit processor
    }

    /// Tests that hits are retried properly and do not block the queue
    func testProcessesHitsManyWithIntermittentProcessor() {
        let hitCount = 50
        hitProcessor = MockHitIntermittentProcessor(hitCount: hitCount)
        hitQueue = PersistentHitQueue(dataQueue: MockDataQueue(), processor: hitProcessor)

        // test
        hitQueue.beginProcessing()
        for i in 0 ..< hitCount {
            hitQueue.queue(entity: DataEntity(uniqueIdentifier: "\(i)", timestamp: Date(), data: nil))
        }

        let intermittentProcessor = hitQueue.processor as? MockHitIntermittentProcessor
        wait(for: [intermittentProcessor!.expectation], timeout: 100)

        // verify
        XCTAssertNil(hitQueue.dataQueue.peek()) // hits should no longer be in the queue as its been processed
        XCTAssertEqual(hitCount, intermittentProcessor?.processedHits.count) // All hits should be eventually processed
        XCTAssertFalse(intermittentProcessor?.failedHits.isEmpty ?? true) // some of the hits should have failed

        // verify hits processed in-order
        for i in 0 ..< (intermittentProcessor?.processedHits.count)! {
            let hit = intermittentProcessor?.processedHits.shallowCopy[i]
            XCTAssertEqual("\(i)", hit?.uniqueIdentifier)
        }
    }

    /// Tests that hits are retried in an efficiently and orderly manner
    func testHitRetryOrdering() {
        let entity1 = DataEntity(uniqueIdentifier: "dataEntity1", timestamp: Date(), data: nil)
        let entity2 = DataEntity(uniqueIdentifier: "dataEntity2", timestamp: Date(), data: nil)
        let entity3 = DataEntity(uniqueIdentifier: "dataEntity3", timestamp: Date(), data: nil)

        hitProcessor = ControllableHitProcessor()
        hitQueue = PersistentHitQueue(dataQueue: MockDataQueue(), processor: hitProcessor)

        guard let mockHitProcessor = hitProcessor as? ControllableHitProcessor else {
            XCTFail()
            return
        }

        mockHitProcessor.hitResult = false // retry hits
        hitQueue.beginProcessing()
        hitQueue.queue(entity: entity1)
        hitQueue.queue(entity: entity2)
        hitQueue.queue(entity: entity3)

        // Sleep 0.1 seconds, which is less than the retry interval of 1 sec, then set hit result to success
        Thread.sleep(forTimeInterval: 0.1)
        mockHitProcessor.hitResult = true // set hit result to success (no retry)
        // Sleep to allow retry interval to pass and data queue to get processed and emptied
        Thread.sleep(forTimeInterval: 2)

        let expectedProcessingOrder = [
            entity1.uniqueIdentifier,
            entity1.uniqueIdentifier, // entity 1 should be the only one retried
            entity2.uniqueIdentifier,
            entity3.uniqueIdentifier]

        XCTAssertNil(hitQueue.dataQueue.peek()) // hits should no longer be in the queue as its been processed
        XCTAssertEqual(expectedProcessingOrder, mockHitProcessor.processedHits.shallowCopy.map({$0.uniqueIdentifier}))
    }
}

class ControllableHitProcessor: HitProcessing {
    let processedHits = ThreadSafeArray<DataEntity>()
    var hitResult = true

    func retryInterval(for entity: DataEntity) -> TimeInterval {
        return 1
    }

    func processHit(entity: DataEntity, completion: @escaping (Bool) -> Void) {
        processedHits.append(entity)
        completion(hitResult)
    }
}

class MockHitProcessor: HitProcessing {
    let processedHits = ThreadSafeArray<DataEntity>()

    func retryInterval(for entity: DataEntity) -> TimeInterval {
        return TimeInterval(1)
    }

    func processHit(entity: DataEntity, completion: (Bool) -> Void) {
        processedHits.append(entity)
        completion(true)
    }
}

class MockHitIntermittentProcessor: HitProcessing {
    let processedHits = ThreadSafeArray<DataEntity>()
    var failedHits = Set<String>()
    let expectation = XCTestExpectation(description: "Hit fulfillment count")

    let processingOrder = ThreadSafeArray<String>()

    /// Creates a new `MockHitIntermittentProcessor`
    /// - Parameter hitCount: Number of hits this processor is expected to process
    init(hitCount: Int) {
        expectation.expectedFulfillmentCount = hitCount
        expectation.assertForOverFulfill = true
    }

    func retryInterval(for entity: DataEntity) -> TimeInterval {
        return TimeInterval(2)
    }

    // 50% of hits need to be processed twice, other 50% process successfully the first time
    func processHit(entity: DataEntity, completion: (Bool) -> Void) {
        processingOrder.append(entity.uniqueIdentifier)

        // check if we've already "failed" at processing this hit
        if failedHits.contains(entity.uniqueIdentifier) {
            processedHits.append(entity)
            expectation.fulfill()
            completion(true)
            return
        }

        if !Bool.random() { // retry ~50% of hits
            processedHits.append(entity)
            expectation.fulfill()
            completion(true)
        } else {
            failedHits.insert(entity.uniqueIdentifier)
            completion(false)
        }
    }
}
