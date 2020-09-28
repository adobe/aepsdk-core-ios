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
import Foundation

public class MockHitQueue: HitQueuing {

    public var processor: HitProcessing
    public var queuedHits = [DataEntity]()

    public var calledBeginProcessing = false
    public var calledSuspend = false
    public var calledClear = false

    public init(processor: HitProcessing) {
        self.processor = processor
    }

    @discardableResult
    public func queue(entity: DataEntity) -> Bool {
        queuedHits.append(entity)
        return true
    }

    public func beginProcessing() {
        calledBeginProcessing = true
    }

    public func suspend() {
        calledSuspend = true
    }

    public func clear() {
        queuedHits.removeAll()
        calledClear = true
    }

    public func count() -> Int {
        return queuedHits.count
    }

    public func close() {
    }
}
