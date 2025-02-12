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
import XCTest

class ThreadSafeDictionaryTests: XCTestCase {
    private var threadSafeDict: ThreadSafeDictionary<Int, Int>!
    private var dispatchQueueSerial: DispatchQueue!
    private var dispatchQueueConcurrent: DispatchQueue!

    override func setUp() {
        threadSafeDict = ThreadSafeDictionary<Int, Int>()
        dispatchQueueSerial = DispatchQueue(label: "ThreadSafeDictionaryTests.serial")
        dispatchQueueConcurrent = DispatchQueue(label: "ThreadSafeDictionaryTests.concurrent", attributes: .concurrent)
    }

    /// Tests 1000 concurrent operations execute as expected
    func testManyConcurrentOperations() {
        // setup
        let count = 1000

        // test
        DispatchQueue.concurrentPerform(iterations: count) { i in
            threadSafeDict[i / 4] = threadSafeDict[i] ?? 0
        }

        // verify
        XCTAssert(threadSafeDict.count == count / 4)
    }

    /// Tests many queues that concurrently write and read to the dictionary
    func testSyncMultipleTimesWithDictionary() {
        // setup
        let count = 1000
        let expectation = self.expectation(description: "Test sync")
        let dispatchQueue1 = DispatchQueue(label: "ThreadSafeDictionaryTests.queue1", attributes: .concurrent)
        let dispatchQueue2 = DispatchQueue(label: "ThreadSafeDictionaryTests.queue2", attributes: .concurrent)
        expectation.expectedFulfillmentCount = count

        // test
        for i in 1 ... count {
            let rand = Int.random(in: 1 ..< 100)
            if rand % 2 == 0 {
                dispatchQueue1.async {
                    self.dispatchSyncWithDict(i: i)
                    expectation.fulfill()
                }
            } else {
                dispatchQueue2.async {
                    self.dispatchSyncWithDict(i: i)
                    expectation.fulfill()
                }
            }
        }

        // verify
        wait(for: [expectation], timeout: 2.0)
    }

    /// Tests that we can concurrently read and write to the dictionary with concurrent queues
    func testConcurrentReadingAndWriting() {
        // setup
        let count = 1000
        let readingQueue = DispatchQueue(label: "ThreadSafeDictionaryTests.readingQueue", attributes: .concurrent)
        let writingQueue = DispatchQueue(label: "ThreadSafeDictionaryTests.writingQueue", attributes: .concurrent)
        let writeExpectation = expectation(description: "Write expectation")
        writeExpectation.expectedFulfillmentCount = count
        let readExpectation = expectation(description: "Read expectation")
        readExpectation.expectedFulfillmentCount = count

        // test
        let key = 0
        for i in 0 ..< count {
            writingQueue.async {
                self.threadSafeDict[key] = i
                writeExpectation.fulfill()
            }

            readingQueue.async {
                _ = self.threadSafeDict[key]
                readExpectation.fulfill()
            }
        }

        // verify
        wait(for: [writeExpectation, readExpectation], timeout: 5.0)
    }

    /// Tests that we can concurrently read and write to the dictionary with concurrent and serial queues
    func testSyncMultipleTimesWithConcurrent() {
        // setup
        let count = 1000
        let expectation = XCTestExpectation(description: "Expectation is full-filled 1000 times")
        expectation.expectedFulfillmentCount = count
        let dispatchQueue1 = DispatchQueue(label: "ThreadSafeDictionaryTests.queue1", attributes: .concurrent)
        let dispatchQueue2 = DispatchQueue(label: "ThreadSafeDictionaryTests.queue2", attributes: .concurrent)

        // test
        for i in 1 ... count {
            let rand = Int.random(in: 1 ..< 100)
            if rand % 2 == 0 {
                dispatchQueue1.async {
                    self.dispatchSyncConcurrentOp(i: i)
                    expectation.fulfill()
                }
            } else {
                dispatchQueue2.async {
                    self.dispatchSyncConcurrentOp(i: i)
                    expectation.fulfill()
                }
            }
        }

        // verify
        wait(for: [expectation], timeout: 5.0)
    }

    /// Tests the .shallowCopy functionality to ensure that it doesn't deadlock and returns the appropriate copy of the backing dictionary
    func testShallowCopyNoDeadlock() {
        let count = 1000
        let testDictionary = ThreadSafeDictionary<Int, Int>()

        for i in 0 ..< count {
            testDictionary[i] = i
        }

        testDictionary.shallowCopy.values.forEach {
            XCTAssertEqual(testDictionary[$0], $0)
        }
    }

    func testGetKeys() {
        let count = 100
        let testDictionary = ThreadSafeDictionary<Int, Int>()

        // get keys on empty dictionary
        XCTAssertEqual(testDictionary.keys,[])

        for i in 0 ..< count {
            testDictionary[i] = i
        }

        XCTAssertEqual(testDictionary.keys.count, count)
    }
    
    func testGetValues() {
        let count = 100
        let testDictionary = ThreadSafeDictionary<Int, Int>()

        // get values on empty dictionary
        XCTAssertEqual(testDictionary.values,[])

        for i in 0 ..< count {
            testDictionary[i] = i
        }

        XCTAssertEqual(testDictionary.values.count, count)
    }
    
    func testIsEmpty() {
        let count = 100
        let testDictionary = ThreadSafeDictionary<Int, Int>()

        XCTAssertTrue(testDictionary.isEmpty)

        for i in 0 ..< count {
            testDictionary[i] = i
        }

        XCTAssertFalse(testDictionary.isEmpty)
    }
    
    func testFilter() {
        let count = 100
        let testDictionary = ThreadSafeDictionary<Int, Int>()

        for i in 0 ..< count {
            testDictionary[i] = i
        }
        
        let filteredDictionary = testDictionary.filter { $0.key % 2 == 0 }
        
        // Verify the filtered dictionary size is half
        XCTAssertEqual(filteredDictionary.count, count / 2)
        
    }
    
    func testMerge() {
        let dict1 = ["key1" : "value1"]
        let testDictionary = ThreadSafeDictionary<String, String>()

        testDictionary.merge(dict1) { (_, new) in new }
        
        let dict2 = ["k1": "v1", "k2": "v2", "k3": "v3", "k4": "v4"]

        testDictionary.merge(dict2) { (_, new) in new }
        
        //verify
        XCTAssertEqual(testDictionary.count, 5)
    }
    
    func testMergeWithMultipleConflictingKeys() {
        // Initial dictionary
        let dict1 = [
            "key1": "value1",
            "key2": "Value2",
            "key3": "Value3",
            "key4": "Value4"
        ]
        
        // Another dictionary with conflicting keys
        let dict2 = [
            "key2": "newValue2",
            "key3": "newValue3",
            "key4": "newValue4",
            "key5": "value5"
        ]

        let testDictionary = ThreadSafeDictionary<String, String>()
        
        testDictionary.merge(dict1) { _, new in new }
        
        // merge with conflicting keys
        testDictionary.merge(dict2) { _, new in new }

        // Verify the dictionary count
        XCTAssertEqual(testDictionary.count, 5)

        // Verify dictionary values
        XCTAssertEqual(testDictionary["key1"], "value1")
        XCTAssertEqual(testDictionary["key2"], "newValue2")
        XCTAssertEqual(testDictionary["key3"], "newValue3")
        XCTAssertEqual(testDictionary["key4"], "newValue4")
        XCTAssertEqual(testDictionary["key5"], "value5")
    }

    
    func testContain() {
        
        let testDictionary = ThreadSafeDictionary<String, String>()
        let dict2 = ["k1": "v1", "k2": "v2", "k3": "v3", "k4": "v4"]

        testDictionary.merge(dict2) { (_, new) in new }
        
        //verify
        XCTAssertTrue(testDictionary.contains(where: { $0.key == "k1" }))
    }
    
    func testChainedOperations() {
        let dict = ThreadSafeDictionary<Int, String>()
        
        // Apply merge operation
        dict.merge([1: "One", 2: "Two", 3: "Three", 4: "Four"]) { _, new in new }
        
        // Apply filter to keep only even keys
        var filtered = dict.filter { key, _ in key % 2 == 0 }
        
        // Check if the filtered dictionary contains a specific value
        let containsTwo = filtered.contains { _, value in value == "Two" }
        XCTAssertTrue(containsTwo)
        
        // Remove all elements from the filtered dictionary
        filtered.removeAll()
        
        // verify
        XCTAssertTrue(filtered.isEmpty)
    }

    private func dispatchSyncWithDict(i: Int) {
        dispatchQueueSerial.sync {
            self.threadSafeDict?[0] = i
        }
    }

    private func dispatchSyncConcurrentOp(i: Int) {
        dispatchQueueSerial.sync {
            dispatchQueueConcurrent.async {
                self.threadSafeDict[0] = i
            }

            dispatchQueueConcurrent.async(flags: .barrier) {
                self.threadSafeDict[0] = i
            }
        }
    }
}
