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
@testable import AEPServices

class FileManagerDirectoriesTests: XCTestCase {
    let fileManager = FileManager.default
    var testDirectoryUrl: URL!
    
    override func setUp() {
        super.setUp()
        
        // Create a unique test directory URL in the caches directory
        let testDirectoryName = "FileManagerDirectoriesTests.\(UUID().uuidString)"
        testDirectoryUrl = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent(testDirectoryName)
    }
    
    override func tearDown() {
        // Clean up test directory
        if let testUrl = testDirectoryUrl, fileManager.fileExists(atPath: testUrl.path) {
            try? fileManager.removeItem(at: testUrl)
        }
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testCreateDirectoryIfNeeded_WhenDirectoryDoesNotExist_ShouldCreateDirectory() {
        // Given - directory does not exist
        XCTAssertFalse(fileManager.fileExists(atPath: testDirectoryUrl.path))
        
        // When
        let result = fileManager.createDirectoryIfNeeded(at: testDirectoryUrl)
        
        // Then
        XCTAssertTrue(result, "createDirectoryIfNeeded should return true when successfully creating directory")
        XCTAssertTrue(fileManager.fileExists(atPath: testDirectoryUrl.path), "Directory should exist after creation")
        
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: testDirectoryUrl.path, isDirectory: &isDirectory)
        XCTAssertTrue(exists, "Path should exist")
        XCTAssertTrue(isDirectory.boolValue, "Path should be a directory")
    }
    
    func testCreateDirectoryIfNeeded_WhenDirectoryAlreadyExists_ShouldReturnTrue() {
        // Given - directory already exists
        try? fileManager.createDirectory(at: testDirectoryUrl, withIntermediateDirectories: true, attributes: nil)
        XCTAssertTrue(fileManager.fileExists(atPath: testDirectoryUrl.path))
        
        // When
        let result = fileManager.createDirectoryIfNeeded(at: testDirectoryUrl)
        
        // Then
        XCTAssertTrue(result, "createDirectoryIfNeeded should return true when directory already exists")
        XCTAssertTrue(fileManager.fileExists(atPath: testDirectoryUrl.path), "Directory should still exist")
    }
    
    func testCreateDirectoryIfNeeded_WithNestedDirectories_ShouldCreateAllIntermediateDirectories() {
        // Given - nested directory path that doesn't exist
        let nestedDirectoryUrl = testDirectoryUrl
            .appendingPathComponent("level1")
            .appendingPathComponent("level2")
            .appendingPathComponent("level3")
        
        XCTAssertFalse(fileManager.fileExists(atPath: nestedDirectoryUrl.path))
        
        // When
        let result = fileManager.createDirectoryIfNeeded(at: nestedDirectoryUrl)
        
        // Then
        XCTAssertTrue(result, "createDirectoryIfNeeded should return true when creating nested directories")
        XCTAssertTrue(fileManager.fileExists(atPath: nestedDirectoryUrl.path), "Nested directory should exist after creation")
        
        // Verify all intermediate directories were created
        XCTAssertTrue(fileManager.fileExists(atPath: testDirectoryUrl.path), "Root test directory should exist")
        XCTAssertTrue(fileManager.fileExists(atPath: testDirectoryUrl.appendingPathComponent("level1").path), "Level 1 directory should exist")
        XCTAssertTrue(fileManager.fileExists(atPath: testDirectoryUrl.appendingPathComponent("level1").appendingPathComponent("level2").path), "Level 2 directory should exist")
    }
    
    func testCreateDirectoryIfNeeded_WhenFileExistsAtPath_ShouldReturnFalse() {
        // Given - a file exists at the target path
        guard let fileUrl = testDirectoryUrl else {
            XCTFail("testDirectoryFailure")
            return
        }
        
        let parentDirectory = fileUrl.deletingLastPathComponent()
        try? fileManager.createDirectory(at: parentDirectory, withIntermediateDirectories: true, attributes: nil)
        
        XCTAssertTrue(fileManager.createFile(atPath: fileUrl.path, contents: Data("test file".utf8), attributes: nil))
        XCTAssertTrue(fileManager.fileExists(atPath: fileUrl.path))
        
        // When
        let result = fileManager.createDirectoryIfNeeded(at: fileUrl)
        
        // Then
        XCTAssertFalse(result, "createDirectoryIfNeeded should return false when a file exists at the target path")
        
        // Verify the file still exists and wasn't replaced
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: fileUrl.path, isDirectory: &isDirectory)
        XCTAssertTrue(exists, "File should still exist")
        XCTAssertFalse(isDirectory.boolValue, "Path should still be a file, not a directory")
    }
    
    func testCreateDirectoryIfNeeded_WithInvalidPermissions_ShouldReturnFalse() {
        // Given - create parent directory with read-only permissions
        let parentDirectory = testDirectoryUrl.deletingLastPathComponent().appendingPathComponent("readonly_parent")
        try? fileManager.createDirectory(at: parentDirectory, withIntermediateDirectories: true, attributes: nil)
        try? fileManager.setAttributes([.posixPermissions: 0o444], ofItemAtPath: parentDirectory.path)
        
        let restrictedDirectoryUrl = parentDirectory.appendingPathComponent("restricted_child")
        
        // When
        let result = fileManager.createDirectoryIfNeeded(at: restrictedDirectoryUrl)
        
        // Then
        XCTAssertFalse(result, "createDirectoryIfNeeded should return false when permissions prevent directory creation")
        XCTAssertFalse(fileManager.fileExists(atPath: restrictedDirectoryUrl.path), "Directory should not exist when creation fails")
        
        // Clean up - restore permissions for tearDown
        try? fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: parentDirectory.path)
        try? fileManager.removeItem(at: parentDirectory)
    }
    
    func testCreateDirectoryIfNeeded_ShouldSetCorrectFileProtection() {
        // Given - directory does not exist
        XCTAssertFalse(fileManager.fileExists(atPath: testDirectoryUrl.path))
        
        // When
        let result = fileManager.createDirectoryIfNeeded(at: testDirectoryUrl)
        
        // Then
        XCTAssertTrue(result, "createDirectoryIfNeeded should succeed")
        
        // Verify file protection attribute
        let attributes = try? fileManager.attributesOfItem(atPath: testDirectoryUrl.path)
        let protection = attributes?[FileAttributeKey.protectionKey] as? FileProtectionType
        XCTAssertNil(protection, "Directory should have no file protection")
    }
    
    func testCreateDirectoryIfNeeded_WithSpecialCharactersInPath_ShouldSucceed() {
        // Given - directory path with special characters
        let specialCharacterUrl = testDirectoryUrl
            .appendingPathComponent("special chars & symbols!")
            .appendingPathComponent("unicode_测试_🚀")
        
        XCTAssertFalse(fileManager.fileExists(atPath: specialCharacterUrl.path))
        
        // When
        let result = fileManager.createDirectoryIfNeeded(at: specialCharacterUrl)
        
        // Then
        XCTAssertTrue(result, "createDirectoryIfNeeded should succeed with special characters in path")
        XCTAssertTrue(fileManager.fileExists(atPath: specialCharacterUrl.path), "Directory with special characters should exist")
    }
    
    func testCreateDirectoryIfNeeded_WithEmptyPathComponents_ShouldHandleGracefully() {
        // Given - URL with empty path components
        let urlWithEmptyComponents = testDirectoryUrl
            .appendingPathComponent("")
            .appendingPathComponent("valid")
            .appendingPathComponent("")
        
        // When
        let result = fileManager.createDirectoryIfNeeded(at: urlWithEmptyComponents)
        
        // Then - should still succeed in creating the directory structure
        XCTAssertTrue(result, "createDirectoryIfNeeded should handle empty path components gracefully")
    }
    
    func testCreateDirectoryIfNeeded_ConcurrentCalls_ShouldBeThreadSafe() {
        // Given - multiple concurrent calls to create the same directory
        let expectation1 = XCTestExpectation(description: "First concurrent call completes")
        let expectation2 = XCTestExpectation(description: "Second concurrent call completes")
        let expectation3 = XCTestExpectation(description: "Third concurrent call completes")
        
        var results: [Bool] = []
        let resultsQueue = DispatchQueue(label: "results", attributes: .concurrent)
        
        // When - make concurrent calls
        DispatchQueue.global().async {
            let result = self.fileManager.createDirectoryIfNeeded(at: self.testDirectoryUrl)
            resultsQueue.async(flags: .barrier) {
                results.append(result)
            }
            expectation1.fulfill()
        }
        
        DispatchQueue.global().async {
            let result = self.fileManager.createDirectoryIfNeeded(at: self.testDirectoryUrl)
            resultsQueue.async(flags: .barrier) {
                results.append(result)
            }
            expectation2.fulfill()
        }
        
        DispatchQueue.global().async {
            let result = self.fileManager.createDirectoryIfNeeded(at: self.testDirectoryUrl)
            resultsQueue.async(flags: .barrier) {
                results.append(result)
            }
            expectation3.fulfill()
        }
        
        // Then
        wait(for: [expectation1, expectation2, expectation3], timeout: 5.0)
        
        XCTAssertTrue(fileManager.fileExists(atPath: testDirectoryUrl.path), "Directory should exist after concurrent calls")
        XCTAssertEqual(results.count, 3, "All concurrent calls should complete")
        XCTAssertTrue(results.allSatisfy { $0 }, "All concurrent calls should return true")
    }
}
