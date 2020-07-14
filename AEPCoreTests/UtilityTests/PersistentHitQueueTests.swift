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

import XCTest
@testable import AEPCore

class PersistentHitQueueTests: XCTestCase {

    var hitQueue: PersistentHitQueue!
    var hitProcessor: HitProcessable!
    var processedHits: [DataEntity] {
        guard let mockProcessor = hitProcessor as? MockHitProcessor else { return [] }
        return mockProcessor.processedHits.shallowCopy
    }
    
    override func setUp() {
        hitQueue = PersistentHitQueue(dataQueue: MockDataQueue())
        hitProcessor = MockHitProcessor()
        hitQueue.delegate = hitProcessor
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
        for _ in 0..<100 {
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
        for _ in 0..<100 {
            hitQueue.queue(entity: DataEntity(uniqueIdentifier: UUID().uuidString, timestamp: Date(), data: nil))
        }
        
        hitQueue.beginProcessing()
        hitQueue.suspend()
        sleep(1)
        
        // verify
        XCTAssertNotNil(hitQueue.dataQueue.peek()) // some hits should still be in the queue
        XCTAssertNotEqual(100, processedHits.count) // we should have not processed all 100 hits by the time we have suspended
    }
    
    /// Tests that not all hits are processed when we suspend the queue, but then when we resume processing that the remaining hits a processed
    func testProcessesHitsManyWithSuspendThenResume() {
        // test
        for _ in 0..<100 {
            hitQueue.queue(entity: DataEntity(uniqueIdentifier: UUID().uuidString, timestamp: Date(), data: nil))
        }
        
        hitQueue.beginProcessing()
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
        hitProcessor = MockHitIntermittentProcessor()
        hitQueue.delegate = hitProcessor
        
        // test
        for _ in 0..<100 {
            hitQueue.queue(entity: DataEntity(uniqueIdentifier: UUID().uuidString, timestamp: Date(), data: nil))
        }
        
        hitQueue.beginProcessing()
        sleep(1)
        
        // verify
        XCTAssertNil(hitQueue.dataQueue.peek()) // hits should no longer be in the queue as its been processed
        let intermittentProcessor = hitQueue.delegate as? MockHitIntermittentProcessor
        XCTAssertEqual(100, intermittentProcessor?.processedHits.count) // all hits should be eventually processed
        XCTAssertFalse(intermittentProcessor?.failedHits.isEmpty ?? true) // some of the hits should have failed
    }


}

class MockHitProcessor: HitProcessable {
    var retryInterval: TimeInterval = 1
    
    let processedHits = ThreadSafeArray<DataEntity>()
    
    func processHit(entity: DataEntity, completion: (Bool) -> ()) {
        processedHits.append(entity)
        completion(true)
    }
}

class MockHitIntermittentProcessor: HitProcessable {
    var retryInterval: TimeInterval = 0
    
    let processedHits = ThreadSafeArray<DataEntity>()
    var failedHits = Set<String>()
    
    // 50% of hits need to be processed twice, other 50% process successfully the first time
    func processHit(entity: DataEntity, completion: (Bool) -> ()) {
        // check if we've already "failed" at processing this hit
        if failedHits.contains(entity.uniqueIdentifier) {
            processedHits.append(entity)
            completion(true)
            return
        }
        
        let shouldRetry = entity.uniqueIdentifier.hashValue % 2 == 0 // retry 50% of hits
        
        if !shouldRetry {
            processedHits.append(entity)
            completion(true)
        } else {
            failedHits.insert(entity.uniqueIdentifier)
            completion(false)
        }
    }
}
