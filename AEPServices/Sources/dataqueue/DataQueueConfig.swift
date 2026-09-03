/*
 Copyright 2026 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation
/// Tuning a consumer registers for its `DataQueue` ahead of creating it.
///
/// The defaults here reproduce the behavior of a queue created without any configuration, so consumers
/// only set what they need to change.
@objc(AEPDataQueueConfig) public class DataQueueConfig: NSObject {
    @objc public var journalMode: SQLiteJournalMode

    @objc public init(journalMode: SQLiteJournalMode = .rollback) {
        self.journalMode = journalMode
    }
}
