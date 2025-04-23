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

@testable import AEPCore

/// Functional tests for the rules engine feature
///
/// for each test case generally:
/// 1. in comments explain the historical consequence being used/tested
/// 2. load the rule into rules engine
/// 3. build and an event that triggers this rule (the event itself any anything related to it outside of causing the consequence is not the point)
/// 4. have rules engine evaluate the rule
/// 5. based on the test case, validate that the event is recorded (or not) - what is dispatched is what is recorded
///
/// however, i think there should be an integration test that it is working e2e, recording and not recording
///
///
class RulesEngineHistoricalTests: RulesEngineTestBase {
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

    func testSchemaConsequenceInsert_doesDispatchAndRecord() {
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
        // Should be dispatched
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        // Should attempt to record into event history
        XCTAssertTrue(mockRuntime.recordHistoricalEventCalled)
    }

    func testSchemaConsequenceInsert_doesDispatchAndRecord_whenTokenReplacement() {
        // Given: a schema type rule consequence with a valid format
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //        "id": "test-id",
        //        "schema": "https://ns.adobe.com/personalization/eventHistoryOperation",
        //        "data": {
        //          "operation": "insert",
        //          "content": {
        //            "key1": "value1",
        //            "tokenKey": "{%~timestampu%}",
        //            "tokenKey2": "{%~sdkver%}"
        //          }
        //        }
        //      }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testSchemaEventHistoryInsert_withTokens")

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should be dispatched
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        // Should attempt to record into event history
        XCTAssertTrue(mockRuntime.recordHistoricalEventCalled)
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
        // Should be dispatched
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        // Should attempt to record into event history
        XCTAssertTrue(mockRuntime.recordHistoricalEventCalled)
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

        // Mock getHistoricalEvents to say event is in event history
        mockRuntime.mockEventHistoryResults = [EventHistoryResult(count: 1)]

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
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
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
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
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
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
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
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
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
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
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
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
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
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
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
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
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
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
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
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
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
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
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
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
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
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
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
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
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
    }

    func testSchemaConsequenceInsert_doesNotDispatchOrRecord_whenContentIsInvalid() {
        // Given: a schema type rule consequence with an invalid format for event history operation: ('content' null)
        //    ---------- schema based consequence details ----------
        //        "detail": {
        //          "id": "test-id",
        //          "schema": "https://ns.adobe.com/personalization/eventHistoryOperation",
        //          "data": {
        //              "operation": "invalid",
        //              "content": null
        //          }
        //        }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "consequence_rules_testDataContentNull")

        // When:
        rulesEngine.process(event: defaultEvent)

        // Then: Event history consequence event:
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
    }

    // This is not an invalid format, but validates the logic for event history operation
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
        // Should not be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        // Should not attempt to record into event history
        XCTAssertFalse(mockRuntime.recordHistoricalEventCalled)
    }
}
