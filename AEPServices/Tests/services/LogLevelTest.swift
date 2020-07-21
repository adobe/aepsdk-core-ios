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

class LogLevelTest: XCTestCase {
    static var currentLogMsg: String = ""
    private let loggingService = AEPServiceProvider.shared.loggingService

    override func setUp() {
        AEPServiceProvider.shared.loggingService = AEPLoggingService()
    }

    func testLogLevelComparer() throws {
        XCTAssertTrue(LogLevel.error > LogLevel.warning)
        XCTAssertTrue(LogLevel.warning > LogLevel.debug)
        XCTAssertTrue(LogLevel.debug > LogLevel.trace)
    }

    func testPrintingDescribableObject() throws {
        AEPServiceProvider.shared.loggingService = CustomLoggingService()
        let obj = ObjA()
        Log.logFilter = .debug
        Log.warning(label: "aep.test", "print ObjA \(describing: obj)")
        XCTAssertTrue(LogLevelTest.currentLogMsg.contains("_sensitive_data_"))
    }

    func testPrintingDescribableObjectWithSensitiveData() throws {
        AEPServiceProvider.shared.loggingService = CustomLoggingService()
        let obj = ObjA()
        Log.logFilter = .debug
        Log.warning(label: "aep.test", "print ObjA \(describing: obj, privacy: .Private)")
        XCTAssertTrue(LogLevelTest.currentLogMsg.contains("_sensitive_data_"))
    }

    func testPrintingDescribableObjectWithoutSensitiveData() throws {
        AEPServiceProvider.shared.loggingService = CustomLoggingService()
        let obj = ObjA()
        Log.logFilter = .warning
        Log.warning(label: "aep.test", "print ObjA \(describing: obj, privacy: .Private)")
        XCTAssertFalse(LogLevelTest.currentLogMsg.contains("_sensitive_data_"))
    }

    func testPrintingNonDescribableObject() throws {
        AEPServiceProvider.shared.loggingService = CustomLoggingService()
        let obj = ObjB()
        Log.logFilter = .debug
        Log.debug(label: "aep.test", "print ObjA \(obj)")
        XCTAssertTrue(LogLevelTest.currentLogMsg.contains("_non_describing_"))
    }
}

class CustomLoggingService: LoggingService {
    func log(level: LogLevel, label: String, message: String) {
        LogLevelTest.currentLogMsg = message
    }
}

struct ObjA: Describable {
    func description(withSensitiveData: Bool) -> String {
        return withSensitiveData ? "_sensitive_data_" : ""
    }
}

struct ObjB: CustomStringConvertible {
    public var description: String {
        return "_non_describing_"
    }
}
