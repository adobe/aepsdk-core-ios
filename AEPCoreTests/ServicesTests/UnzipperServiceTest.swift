//
//  UnzipperServiceTest.swift
//  AEPCoreTests
//
//  Created by Christopher Hoffman on 6/4/20.
//  Copyright © 2020 Adobe. All rights reserved.
//

import XCTest
@testable import AEPCore

class UnzipperServiceTest: XCTestCase {
    let unzipper = RulesUnzipper()
    let testDataFileName = "TestRules"

    override func setUp() {
        
    }
    
    func testUnzippingRulesSimple() {
        let bundle = Bundle(for: type(of: self))
        let expectation = XCTestExpectation(description: "Unzip test file")
        if let testFilePath = bundle.path(forResource: testDataFileName, ofType: "zip") {
            let destinationPath = testFilePath.replacingOccurrences(of: ".zip", with: ".txt")
            unzipper.unzip(fromPath: testFilePath, to: destinationPath, completion: {
                expectation.fulfill()
            })
        }
        
        wait(for: [expectation], timeout: 0.5)
    }
}
