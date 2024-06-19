/*
 Copyright 2024 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import XCTest

@testable import AEPServices

class URLErrorRecoverableTests: XCTestCase {

    func test_isrecoverable_recoverableErrors_returnsTrue() {
        let recoverableErrors = [
            URLError.timedOut,
            URLError.cannotConnectToHost,
            URLError.networkConnectionLost,
            URLError.notConnectedToInternet,
            URLError.dataNotAllowed
        ]

        recoverableErrors.forEach { errorCode in
            XCTAssertTrue(URLError(errorCode).isRecoverable, "\(errorCode) should be recoverable")
        }
    }

    func test_isrecoverable_unrecoverableErrors_returnsFalse() {
        let unrecoverableErrors = [
            URLError.cannotFindHost,
            URLError.secureConnectionFailed,
            URLError.serverCertificateNotYetValid,
            URLError.unknown,
            URLError.badURL
        ]

        unrecoverableErrors.forEach { errorCode in
            XCTAssertFalse(URLError(errorCode).isRecoverable, "\(errorCode) should not be recoverable")
        }
    }
}

