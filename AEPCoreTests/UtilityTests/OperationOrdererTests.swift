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

class OperationOrdererTests: XCTestCase {
    let itemCount = 1000 /// Used by all tests that test multiple queue items
    let threadCount = 10 /// Used by all tests that test multiple threads
    
    /// testBasicFunctionality tests the simple case of running some items through an `OperationOrderer`
    func testBasicFunctionality() {
        let expectation = XCTestExpectation()
        expectation.assertForOverFulfill = true
        expectation.expectedFulfillmentCount = itemCount
        
        let queue = OperationOrderer<Int>()
        queue.setHandler { (_) -> Bool in
            expectation.fulfill()
            return true
        }
        
        // dispatch items
        for i in 0..<itemCount {
            queue.add(i)
        }
        
        queue.start()
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// testBasicFunctionalityAfterDelay tests the simple case of running some items through an `OperationOrderer` with a delay
    func testBasicFunctionalityAfterDelay() {
        let expectation = XCTestExpectation()
        expectation.assertForOverFulfill = true
        expectation.expectedFulfillmentCount = itemCount
        
        let queue = OperationOrderer<Int>()
        queue.setHandler { (_) -> Bool in
            expectation.fulfill()
            return true
        }
        
        // dispatch items
        for i in 0..<itemCount {
            queue.add(i)
        }
        
        queue.start(after: 0.25)
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Make sure we can destroy an OperationOrderer without any dangling suspended GCD stuff (which would crash)
    func testCanDestroy() {
        var queue: OperationOrderer? = OperationOrderer<Int>()
        queue = nil
        XCTAssert(queue == nil)
    }
    
    /// Ensure destroying an OperationOrderer without any dangling suspended GCD stuff after a start.
    func testCanDestroyAfterStart() {
        var queue: OperationOrderer? = OperationOrderer<Int>()
        queue!.start()
        queue = nil
        XCTAssert(queue == nil)
    }
     
    /// Ensure starting an operation queue with an empty handler doesn't empty the queue.
    func testOperationOrdererDoesntEmptyIfHandlerFunctionReturnsFalse() {
        let expectation = XCTestExpectation()
        expectation.assertForOverFulfill = true
        
        let queue = OperationOrderer<Int>()
        queue.setHandler { (_) -> Bool in
            expectation.fulfill()
            return false
        }
        
        for i in 0..<itemCount {
            queue.add(i)
        }
        queue.start()
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Ensure that queued items are processed by handler function in FIFO order.
    func testOperationOrdererMaintainsOrder() {
        let expectation = XCTestExpectation()
        expectation.assertForOverFulfill = true
        expectation.expectedFulfillmentCount = itemCount
        
        var counter = 0
        
        let queue = OperationOrderer<Int>()
        queue.setHandler { (item: Int) -> Bool in
            XCTAssert(counter == item)
            counter += 1
            expectation.fulfill()
            return true
        }
        
        for i in 0..<itemCount {
            queue.add(i)
        }
        
        queue.start()
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Ensure that an OperationOrderer can be started and stopped multiple times.
    func testOperationOrdererMultipleStartStop() {
        let firstSetExpectation = XCTestExpectation()
        firstSetExpectation.assertForOverFulfill = true
        firstSetExpectation.expectedFulfillmentCount = itemCount
        let secondSetExpectation = XCTestExpectation()
        secondSetExpectation.assertForOverFulfill = true
        secondSetExpectation.expectedFulfillmentCount = itemCount
                
        var firstSetCounter = 0
        var secondSetCounter = 0
        
        let queue = OperationOrderer<Int>()
        queue.setHandler { (item: Int) -> Bool in
            if item < self.itemCount {
                firstSetExpectation.fulfill()
                firstSetCounter += 1
            } else {
                secondSetExpectation.fulfill()
                secondSetCounter += 1
            }
            return true
        }
        
        for i in 0..<itemCount {
            queue.add(i)
        }
        
        queue.start()
        queue.stop()
        wait(for: [firstSetExpectation], timeout: 1.0)
        XCTAssert(firstSetCounter == itemCount)
        XCTAssert(secondSetCounter == 0)
        
        firstSetCounter = 0
        for i in itemCount..<itemCount*2 {
            queue.add(i)
        }
                
        queue.start()
        queue.stop()
        wait(for: [secondSetExpectation], timeout: 1.0)
        XCTAssert(firstSetCounter == 0)
        XCTAssert(secondSetCounter == itemCount)
    }
    
    /// Ensure that multiple threads can dispatch items to the same OperationOrderer
    func testMultithreadedProducers() {
        let expectation = XCTestExpectation()
        expectation.assertForOverFulfill = true
        expectation.expectedFulfillmentCount = itemCount * threadCount
        
        let queue = OperationOrderer<Int>()
        queue.setHandler { (_) -> Bool in
            expectation.fulfill()
            return true
        }
        queue.start()
        
        for _ in 0..<threadCount {
            DispatchQueue.global().async {
                for i in 0..<self.itemCount {
                    queue.add(i)
                }
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Ensure that items queued prior to a start, then a start, then a handler gets assigned works.
    func testItemsQueuedAndStartedPriorToHandlerStillGetProcessed() {
        let expectation = XCTestExpectation()
        expectation.assertForOverFulfill = true
        expectation.expectedFulfillmentCount = itemCount
        
        let queue = OperationOrderer<Int>()
        queue.start()
        
        for i in 0..<itemCount {
            queue.add(i)
        }

        queue.setHandler { (_) -> Bool in
            expectation.fulfill()
            return true
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Ensure that handlers can be swapped while a queue is running, and that ordering is maintained.
    /// (e.g. all items queued prior to the swap are handled by the first handler, and all items queued after the swap are handled by the second handler)
    func testMidRunHandlerSwap() {
        let firstHandlerExpectation = XCTestExpectation()
        firstHandlerExpectation.assertForOverFulfill = true
        firstHandlerExpectation.expectedFulfillmentCount = itemCount
        
        let secondHandlerExpectation = XCTestExpectation()
        secondHandlerExpectation.assertForOverFulfill = true
        secondHandlerExpectation.expectedFulfillmentCount = itemCount
        
        let queue = OperationOrderer<Int>()
        queue.start()

        queue.setHandler { (_) -> Bool in
            firstHandlerExpectation.fulfill()
            return true
        }
        
        for i in 0..<itemCount {
            queue.add(i)
        }
                
        queue.setHandler { (_) -> Bool in
            secondHandlerExpectation.fulfill()
            return true
        }
        
        for i in 0..<itemCount {
            queue.add(i)
        }
        
        wait(for: [firstHandlerExpectation, secondHandlerExpectation], timeout: 1.0)
    }

}
