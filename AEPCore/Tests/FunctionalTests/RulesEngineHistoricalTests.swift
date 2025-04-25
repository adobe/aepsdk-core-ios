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

import XCTest

import AEPServicesMocks

@testable import AEPCore

class RulesEngineHistoricalTests: RulesEngineTestBase, AnyCodableAsserts {
    override func setUp() {
        super.setUp()
        defaultEvent = Event(name: "Test Event",
                             type: EventType.genericTrack,
                             source: EventSource.requestContent,
                             data: nil)
    }

    // MARK: - Valid input tests
    func testSchemaConsequenceInsert_doesDispatchAndRecord_whenDetailIdIsEmpty() {
        // Given: a schema type rule consequence with a valid format
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //          "id": "",
        //          "schema": "https://ns.adobe.com/personalization/eventHistoryOperation",
        //          "data": {
        //              "operation": "insert",
        //              "content": {
        //                  "key1": "value1"
        //              }
        //          }
        //        }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testSchemaIdEmpty")

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should be dispatched
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        // Should attempt to record into event history
        XCTAssertTrue(mockRuntime.recordHistoricalEventCalled)
    }

    func testSchemaConsequenceInsert_doesDispatchAndRecord() throws {
        // Given: a schema type rule consequence with a valid format
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //        "id": "test-id",
        //        "schema": "https://ns.adobe.com/personalization/eventHistoryOperation",
        //        "data": {
        //          "operation": "insert",
        //          "content": {
        //            "stringKey": "stringValue",
        //            "numberKey": 123,
        //            "booleanKey": true,
        //            "arrayKey": ["value1", 2, false],
        //            "objectKey": {
        //              "nestedKey1": "nestedValue1",
        //              "nestedKey2": 456,
        //              "nestedKey3": false
        //            },
        //            "nullKey": null
        //          }
        //        }
        //      }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testSchemaEventHistoryInsert")

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should attempt to record into event history
        XCTAssertTrue(mockRuntime.recordHistoricalEventCalled)
        // Should be dispatched
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)

        // Validate that the event that was recorded is equal to what was dispatched
        let recordedEvent = try XCTUnwrap(mockRuntime.receivedRecordHistoricalEvent, "Expected recorded event to be non-nil")
        let dispatchedEvent = try XCTUnwrap(mockRuntime.dispatchedEvents.first, "Expected dispatched event to be non-nil")

        XCTAssertEqual(recordedEvent, dispatchedEvent)

        // Validate the expected consequence event properties: parentID, name, type, source, data
        let expectedEventData = """
        {
          "stringKey": "stringValue",
          "numberKey": 123,
          "booleanKey": true,
          "arrayKey": [
            "value1",
            2,
            false
          ],
          "objectKey": {
            "nestedKey1": "nestedValue1",
            "nestedKey2": 456,
            "nestedKey3": false
          },
          "nullKey": null
        }
        """
        assertEqual(expected: expectedEventData, actual: recordedEvent.data)
        XCTAssertEqual(recordedEvent.parentID, defaultEvent.id)
        XCTAssertEqual(recordedEvent.name, "Dispatch Consequence Result")
        XCTAssertEqual(recordedEvent.type, "com.adobe.eventType.rulesEngine")
        XCTAssertEqual(recordedEvent.source, "com.adobe.eventSource.responseContent")
    }

    func testSchemaConsequenceInsert_doesNotDispatchOrRecord_whenContentIsEmpty() {
        // Given: a schema type rule consequence with an invalid format for event history operation: ('content' empty)
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //          "id": "test-id",
        //          "schema": "https://ns.adobe.com/personalization/eventHistoryOperation",
        //          "data": {
        //              "operation": "invalid",
        //              "content": {}
        //          }
        //        }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testDataContentEmpty")

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testSchemaConsequenceInsert_doesDispatchAndRecord_whenTokenReplacement() throws {
        // Given: a schema type rule consequence with a valid format
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //        "id": "test-id",
        //        "schema": "https://ns.adobe.com/personalization/eventHistoryOperation",
        //        "data": {
        //          "operation": "insert",
        //          "content": {
        //            "key1": "value1",
        //            "tokenKey_type": "{%~type%}",
        //            "tokenKey_source": "{%~source%}"
        //          }
        //        }
        //      }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testSchemaEventHistoryInsert_withTokens")

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should attempt to record into event history
        XCTAssertTrue(mockRuntime.recordHistoricalEventCalled)
        // Should be dispatched
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        // Validate the proper construction of the historical event when tokens are used
        let recordedEvent = try XCTUnwrap(mockRuntime.receivedRecordHistoricalEvent, "Expected recorded event to be non-nil")
        let expectedEventData = """
        {
          "key1": "value1",
          "tokenKey_type": "com.adobe.eventType.generic.track",
          "tokenKey_source": "com.adobe.eventSource.requestContent"
        }
        """
        assertEqual(expected: expectedEventData, actual: recordedEvent.data)
    }

    func testSchemaConsequenceInsert_doesNotDispatch_whenRecordHistoricalEventFails() {
        // Given: a schema type rule consequence with a valid format
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //        "id": "test-id",
        //        "schema": "https://ns.adobe.com/personalization/eventHistoryOperation",
        //        "data": {
        //          "operation": "insert",
        //          "content": {
        //            "stringKey": "stringValue",
        //            ...
        //          }
        //        }
        //      }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testSchemaEventHistoryInsert")

        // Configure recordHistoricalEvent to return failure
        mockRuntime.recordHistoricalEventResult = false

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should attempt to record into event history
        XCTAssertTrue(mockRuntime.recordHistoricalEventCalled)
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testSchemaConsequenceInsertIfNotExists_doesDispatchAndRecord_whenEventNotInEventHistory() {
        // Given: a schema type rule consequence with a valid format
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //        "id": "test-id",
        //        "schema": "https://ns.adobe.com/personalization/eventHistoryOperation",
        //        "data": {
        //          "operation": "insertIfNotExists",
        //          "content": {
        //            "stringKey": "stringValue",
        //            "numberKey": 123,
        //            "booleanKey": true,
        //            "arrayKey": ["value1", 2, false],
        //            "objectKey": {
        //              "nestedKey1": "nestedValue1",
        //              "nestedKey2": 456,
        //              "nestedKey3": false
        //            },
        //            "nullKey": null
        //          }
        //        }
        //      }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testSchemaEventHistoryInsertIfNotExists")

        // Mock getHistoricalEvents to say event is not in event history
        mockRuntime.mockEventHistoryResults = [EventHistoryResult(count: 0)]

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should attempt to record into event history
        XCTAssertTrue(mockRuntime.recordHistoricalEventCalled)
        // Should be dispatched
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
    }

    func testSchemaConsequenceInsertIfNotExists_doesNotDispatchAndRecord_whenEventInEventHistory() {
        // Given: a schema type rule consequence with a valid format
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //        "id": "test-id",
        //        "schema": "https://ns.adobe.com/personalization/eventHistoryOperation",
        //        "data": {
        //          "operation": "insertIfNotExists",
        //          "content": {
        //            "stringKey": "stringValue",
        //            ...
        //          }
        //        }
        //      }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testSchemaEventHistoryInsertIfNotExists")

        // Mock getHistoricalEvents to say event is in event history
        mockRuntime.mockEventHistoryResults = [EventHistoryResult(count: 1)]

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testSchemaConsequenceInsertIfNotExists_doesNotDispatchAndRecord_whenDatabaseError() {
        // Given: a schema type rule consequence with a valid format
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //        "id": "test-id",
        //        "schema": "https://ns.adobe.com/personalization/eventHistoryOperation",
        //        "data": {
        //          "operation": "insertIfNotExists",
        //          "content": {
        //            "stringKey": "stringValue",
        //            ...
        //          }
        //        }
        //      }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testSchemaEventHistoryInsertIfNotExists")

        // Mock getHistoricalEvents to return a database error result
        mockRuntime.mockEventHistoryResults = [EventHistoryResult(count: -1)]

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    // MARK: - Invalid input tests
    // MARK: Invalid schema type consequence `detail` formats
    func testSchemaConsequenceInsert_doesNotDispatchOrRecord_whenDetailIdIsMissing() {
        // Given: a schema type rule consequence with an invalid format: ('id' missing)
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //          "schema": "https://ns.adobe.com/personalization/eventHistoryOperation",
        //          "data": {
        //              "operation": "insert",
        //              "content": {
        //                  "key1": "value1"
        //              }
        //          }
        //        }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testSchemaIdMissing")

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testSchemaConsequenceInsert_doesNotDispatchOrRecord_whenDetailIdIsNull() {
        // Given: a schema type rule consequence with an invalid format: ('id' null)
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //          "id": null,
        //          "schema": "https://ns.adobe.com/personalization/eventHistoryOperation",
        //          "data": {
        //              "operation": "insert",
        //              "content": {
        //                  "key1": "value1"
        //              }
        //          }
        //        }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testSchemaIdNull")

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testSchemaConsequenceInsert_doesNotDispatchOrRecord_whenDetailSchemaIsMissing() {
        // Given: a schema type rule consequence with an invalid format: ('schema' missing)
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //          "id": "test-id",
        //          "data": {
        //              "operation": "insert",
        //              "content": {
        //                  "key1": "value1"
        //              }
        //          }
        //        }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testSchemaSchemaMissing")

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testSchemaConsequenceInsert_doesNotDispatchOrRecord_whenDetailSchemaIsNull() {
        // Given: a schema type rule consequence with an invalid format: ('schema' null)
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //          "id": "test-id",
        //          "schema": null,
        //          "data": {
        //              "operation": "insert",
        //              "content": {
        //                  "key1": "value1"
        //              }
        //          }
        //        }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testSchemaSchemaNull")

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testSchemaConsequenceInsert_doesNotDispatchOrRecord_whenDetailSchemaIsEmpty() {
        // Given: a schema type rule consequence with an invalid format for event history operation: ('schema' = "")
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //          "id": "test-id",
        //          "schema": "",
        //          "data": {
        //              "operation": "insert",
        //              "content": {
        //                  "key1": "value1"
        //              }
        //          }
        //        }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testSchemaSchemaEmpty")

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testSchemaConsequenceInsert_doesNotDispatchOrRecord_whenDetailSchemaIsInvalid() {
        // Given: a schema type rule consequence with an invalid format for event history operation: ('schema' invalidSchema)
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //          "id": "test-id",
        //          "schema": "https://ns.adobe.com/personalization/invalidSchema",
        //          "data": {
        //              "operation": "insert",
        //              "content": {
        //                  "key1": "value1"
        //              }
        //          }
        //        }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testSchemaSchemaInvalid")

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testSchemaConsequenceInsert_doesNotDispatchOrRecord_whenDetailDataIsMissing() {
        // Given: a schema type rule consequence with an invalid format: ('data' missing)
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //          "id": "test-id",
        //          "schema": "https://ns.adobe.com/personalization/eventHistoryOperation"
        //        }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testSchemaDataMissing")

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testSchemaConsequenceInsert_doesNotDispatchOrRecord_whenDetailDataIsNull() {
        // Given: a schema type rule consequence with an invalid format: ('data' null)
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //          "id": "test-id",
        //          "schema": "https://ns.adobe.com/personalization/eventHistoryOperation",
        //          "data": null
        //        }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testSchemaDataNull")

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testSchemaConsequenceInsert_doesNotDispatchOrRecord_whenDetailDataIsEmpty() {
        // Given: a schema type rule consequence with an invalid format: ('data' empty)
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //          "id": "test-id",
        //          "schema": "https://ns.adobe.com/personalization/eventHistoryOperation",
        //          "data": {}
        //        }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testSchemaDataEmpty")

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    // MARK: Invalid `schema` type rule consequence `detail.data` formats
    func testSchemaConsequenceInsert_doesNotDispatchOrRecord_whenOperationIsMissing() {
        // Given: a schema type rule consequence with an invalid format for event history operation: ('operation' missing)
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //          "id": "test-id",
        //          "schema": "https://ns.adobe.com/personalization/eventHistoryOperation",
        //          "data": {
        //              "content": {
        //                  "key1": "value1"
        //              }
        //          }
        //        }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testDataOperationMissing")

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testSchemaConsequenceInsert_doesNotDispatchOrRecord_whenOperationIsNull() {
        // Given: a schema type rule consequence with an invalid format for event history operation: ('operation' null)
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //          "id": "test-id",
        //          "schema": "https://ns.adobe.com/personalization/eventHistoryOperation",
        //          "data": {
        //              "operation": null,
        //              "content": {
        //                  "key1": "value1"
        //              }
        //          }
        //        }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testDataOperationNull")

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testSchemaConsequenceInsert_doesNotDispatchOrRecord_whenOperationIsEmpty() {
        // Given: a schema type rule consequence with an invalid format for event history operation: ('operation' empty)
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //          "id": "test-id",
        //          "schema": "https://ns.adobe.com/personalization/eventHistoryOperation",
        //          "data": {
        //              "operation": "",
        //              "content": {
        //                  "key1": "value1"
        //              }
        //          }
        //        }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testDataOperationEmpty")

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testSchemaConsequenceInsert_doesNotDispatchOrRecord_whenOperationIsInvalid() {
        // Given: a schema type rule consequence with an invalid format for event history operation: ('operation' invalid)
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //          "id": "test-id",
        //          "schema": "https://ns.adobe.com/personalization/eventHistoryOperation",
        //          "data": {
        //              "operation": "invalid",
        //              "content": {
        //                  "key1": "value1"
        //              }
        //          }
        //        }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testDataOperationInvalid")

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testSchemaConsequenceInsert_doesNotDispatchOrRecord_whenContentIsMissing() {
        // Given: a schema type rule consequence with an invalid format for event history operation: ('content' missing)
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //          "id": "test-id",
        //          "schema": "https://ns.adobe.com/personalization/eventHistoryOperation",
        //          "data": {
        //              "operation": "insert"
        //          }
        //        }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testDataContentMissing")

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testSchemaConsequenceInsert_doesNotDispatchOrRecord_whenContentIsNull() {
        // Given: a schema type rule consequence with an invalid format for event history operation: ('content' null)
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //          "id": "test-id",
        //          "schema": "https://ns.adobe.com/personalization/eventHistoryOperation",
        //          "data": {
        //              "operation": "insert",
        //              "content": null
        //          }
        //        }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testDataContentNull")

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }
}
