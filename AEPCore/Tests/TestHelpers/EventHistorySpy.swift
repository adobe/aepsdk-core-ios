/*
 Copyright 2025 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
*/

@testable import AEPCore
@testable import AEPCoreMocks

class EventHistorySpy: EventHistory {
    override init() {
        super.init(mockDB: MockEventHistoryDatabase())
    }

    var didCallGetEvents = false
    var receivedRequests: [EventHistoryRequest]?
    var receivedEnforceOrder: Bool?
    var stubbedResults: [EventHistoryResult] = []

    override func getEvents(_ requests: [EventHistoryRequest],
                            enforceOrder: Bool,
                            handler: @escaping ([EventHistoryResult]) -> Void) {
        didCallGetEvents = true
        receivedRequests = requests
        receivedEnforceOrder = enforceOrder
        handler(stubbedResults)
    }

    var didCallRecordEvent = false
    var recordedEvent: Event?
    var recordHandlerWasCalledWith: Bool?

    override func recordEvent(_ event: Event, handler: ((Bool) -> Void)?) {
        didCallRecordEvent = true
        recordedEvent = event
        handler?(true)
        recordHandlerWasCalledWith = true
    }
}
