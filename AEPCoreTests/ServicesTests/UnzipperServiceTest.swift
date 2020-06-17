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
    
    class var bundle: Bundle {
        return Bundle(for: self)
    }

    override func setUp() {
    }
    
    func cleanUp() {
        do {
            let fileManager = FileManager()
            guard let path = UnzipperServiceTest.bundle.url(forResource: testDataFileName, withExtension: "zip")?.deletingLastPathComponent().appendingPathComponent("directory") else {
                return
            }
            try fileManager.removeItem(at: path)
        } catch {
            return
        }
    }
    
    func testUnzippingRulesSimple() {
        cleanUp()
        let fileManager = FileManager()
        guard let sourceURL = UnzipperServiceTest.bundle.url(forResource: testDataFileName, withExtension: "zip") else {
            XCTFail()
            return
        }
        guard let archive = Archive(url: sourceURL, accessMode: .read) else {
            XCTFail("Failed to create archive")
            return
        }
        
        var destinationURL = sourceURL.deletingLastPathComponent()
        destinationURL.appendPathComponent("directory")
        do {
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            try fileManager.unzipItem(at: sourceURL, to: destinationURL)
        } catch {
            XCTFail("Failed to extract item - \(error)")
            return
        }
        
        var itemExists = false
        for entry in archive {
            let directoryURL = destinationURL.appendingPathComponent(entry.path)
            itemExists = fileManager.itemExists(at: directoryURL)
            if !itemExists { break }
        }
        
        XCTAssert(itemExists)
        
        
    }
}
