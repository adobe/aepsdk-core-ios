//
// Copyright 2023 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

@testable import AEPServices
@testable import AEPCore
import XCTest

class ClassFinderTests: XCTestCase {


    func testClassFinderSimple() {
        let foundExtensions = ClassFinder.classes(conformToProtocol: ExtensionDiscovery.self)
        XCTAssertEqual(foundExtensions.count, 3) // All Extensions in AEPCore
        XCTAssertTrue(foundExtensions.contains { return $0 == SampleExtensionOne.self })
        XCTAssertTrue(foundExtensions.contains { return $0 == SampleExtensionTwo.self })
        XCTAssertTrue(foundExtensions.contains { return $0 == SampleExtensionThree.self })
    }

    @available(iOS 13.0, tvOS 13.0, *)
    func testClassFinderSimpleLoop() {
        let measureOptions = XCTMeasureOptions()
        measureOptions.iterationCount = 10
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric(), XCTCPUMetric()], options: measureOptions) {
            let foundExtensions = ClassFinder.classes(conformToProtocol: ExtensionDiscovery.self)
            XCTAssertEqual(foundExtensions.count, 3) // All Extensions in AEPCore
        }
    }
}

@objc protocol ExtensionDiscovery { }

class SampleExtensionOne: NSObject, ExtensionDiscovery {}

class SampleExtensionTwo: NSObject, ExtensionDiscovery {}

class SampleExtensionThree: NSObject, ExtensionDiscovery {}
