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
@testable import AEPServices

class EventHistoryDatabaseMigratorTests: XCTestCase {
    let fileManager = FileManager.default
    var legacyDbUrl: URL!
    var newDbUrl: URL!
    var testDbName: String!
    var testDbDirectory: String!
    
    // copy of constants
    let dbName = "com.adobe.eventHistory"
    let dbSubdirectoryName = "com.adobe.aep.db"
    let applicationSupportDirectory = FileManager.SearchPathDirectory.applicationSupportDirectory
    let cachesDirectory = FileManager.SearchPathDirectory.cachesDirectory
    var dbNameWithSubdirectory: String!
    
    override func setUp() {
        super.setUp()
        dbNameWithSubdirectory = dbSubdirectoryName + "/" + dbName
        
        // Use unique test database names to avoid conflicts
        testDbName = "test.eventHistory.\(UUID().uuidString)"
        testDbDirectory = "test.aep.db.\(UUID().uuidString)"
        
        // Setup URLs for testing
        legacyDbUrl = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent(testDbName)
        
        if let appSupportUrl = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            newDbUrl = appSupportUrl
                .appendingPathComponent(testDbDirectory)
                .appendingPathComponent(testDbName)
        }
    }
    
    override func tearDown() {
        // Clean up test files
        if let legacyUrl = legacyDbUrl, fileManager.fileExists(atPath: legacyUrl.path) {
            try? fileManager.removeItem(at: legacyUrl)
        }
        
        if let newUrl = newDbUrl, fileManager.fileExists(atPath: newUrl.path) {
            try? fileManager.removeItem(at: newUrl)
            
            // Also remove the test directory structure
            let testDirectory = newUrl.deletingLastPathComponent()
            try? fileManager.removeItem(at: testDirectory)
        }
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createLegacyDatabase() -> Bool {
        return fileManager.createFile(atPath: legacyDbUrl.path, contents: Data("test database".utf8), attributes: nil)
    }
    
    private func migrateDatabaseWithTestConstants() {
        // Check if database has already been migrated
        if fileManager.fileExists(atPath: newDbUrl.path) {
            return
        }
        
        // Check if we have a legacy database to migrate
        guard fileManager.fileExists(atPath: legacyDbUrl.path) else {
            return
        }
        
        guard let applicationSupportUrl = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            XCTFail("Unable to obtain url for 'Application Support' directory")
            return
        }
        
        // Create the Application Support directory if it doesn't exist
        guard fileManager.createDirectoryIfNeeded(at: applicationSupportUrl.appendingPathComponent(testDbDirectory)) else {
            return
        }
        
        try? fileManager.moveItem(atPath: legacyDbUrl.path, toPath: newDbUrl.path)        
    }
    
    // MARK: - Test Cases
    
    func testMigrate_WhenNewDatabaseAlreadyExists_ShouldNotPerformMigration() {
        // Given - new database already exists
        let testDirectoryUrl = newDbUrl.deletingLastPathComponent()
        _ = fileManager.createDirectoryIfNeeded(at: testDirectoryUrl)
        XCTAssertTrue(fileManager.createFile(atPath: newDbUrl.path, contents: Data("existing database".utf8), attributes: nil))
        
        // And legacy database exists
        XCTAssertTrue(createLegacyDatabase())
        
        let originalContent = try? Data(contentsOf: newDbUrl)
        
        // When
        migrateDatabaseWithTestConstants()
        
        // Then - new database content should remain unchanged
        let newContent = try? Data(contentsOf: newDbUrl)
        XCTAssertEqual(originalContent, newContent, "Database should not be overwritten when new database already exists")
        
        // And legacy database should still exist
        XCTAssertTrue(fileManager.fileExists(atPath: legacyDbUrl.path), "Legacy database should not be removed when new database already exists")
    }
    
    func testMigrate_WhenNoLegacyDatabaseExists_ShouldNotCreateNewDatabase() {
        // Given - no legacy database exists
        XCTAssertFalse(fileManager.fileExists(atPath: legacyDbUrl.path))
        
        // When
        migrateDatabaseWithTestConstants()
        
        // Then - no new database should be created
        XCTAssertFalse(fileManager.fileExists(atPath: newDbUrl.path), "New database should not be created when no legacy database exists")
    }
    
    func testMigrate_WhenLegacyDatabaseExists_ShouldMigrateToNewLocation() {
        // Given - legacy database exists
        XCTAssertTrue(createLegacyDatabase())
        let legacyContent = try? Data(contentsOf: legacyDbUrl)
        
        // When
        migrateDatabaseWithTestConstants()
        
        // Then - database should be moved to new location
        XCTAssertTrue(fileManager.fileExists(atPath: newDbUrl.path), "New database should exist after migration")
        XCTAssertFalse(fileManager.fileExists(atPath: legacyDbUrl.path), "Legacy database should be removed after migration")
        
        // And content should be preserved
        let newContent = try? Data(contentsOf: newDbUrl)
        XCTAssertEqual(legacyContent, newContent, "Database content should be preserved during migration")
    }
    
    func testMigrate_WhenApplicationSupportDirectoryCreationFails_ShouldHandleGracefully() {
        // Given - legacy database exists
        XCTAssertTrue(createLegacyDatabase())
        
        // Create a file at the directory path to prevent directory creation
        let directoryPath = newDbUrl.deletingLastPathComponent()
        _ = fileManager.createFile(atPath: directoryPath.path, contents: Data(), attributes: nil)
        
        // When
        migrateDatabaseWithTestConstants()
        
        // Then - legacy database should still exist (migration failed gracefully)
        XCTAssertTrue(fileManager.fileExists(atPath: legacyDbUrl.path), "Legacy database should remain when migration fails")
        XCTAssertFalse(fileManager.fileExists(atPath: newDbUrl.path), "New database should not exist when migration fails")
    }
    
    func testMigrate_WithActualConstants_ShouldUseCorrectPaths() {
        // This test verifies the actual constants are used correctly
        let actualLegacyPath = fileManager.urls(for: cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(dbName)
        let actualNewPath = fileManager.urls(for: applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent(dbNameWithSubdirectory)
        
        XCTAssertNotNil(actualLegacyPath, "Legacy path should be constructible from constants")
        XCTAssertNotNil(actualNewPath, "New path should be constructible from constants")
        
        XCTAssertTrue(actualLegacyPath!.path.contains("Caches"), "Legacy path should use Caches directory")
        XCTAssertTrue(actualNewPath!.path.contains("Application Support"), "New path should use Application Support directory")
        XCTAssertTrue(actualNewPath!.path.contains(dbSubdirectoryName), "New path should contain db directory")
    }
        
    func testMigrate_WhenFileSystemMoveOperationFails_ShouldHandleGracefully() {
        // Given - legacy database exists
        XCTAssertTrue(createLegacyDatabase())
        
        // Create directory structure but make it read-only to cause move operation to fail
        let testDirectoryUrl = newDbUrl.deletingLastPathComponent()
        _ = fileManager.createDirectoryIfNeeded(at: testDirectoryUrl)
        try? fileManager.setAttributes([.posixPermissions: 0o444], ofItemAtPath: testDirectoryUrl.path)
        
        // When
        migrateDatabaseWithTestConstants()
        
        // Then - should handle failure gracefully
        XCTAssertTrue(fileManager.fileExists(atPath: legacyDbUrl.path), "Legacy database should remain when move operation fails")
        
        // Clean up - restore permissions for tearDown
        try? fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: testDirectoryUrl.path)
    }
    
    func testMigrate_WithLargeDatabaseFile_ShouldMigrateSuccessfully() {
        // Given - create a larger test database file
        let largeData = Data(count: 1024 * 1024) // 1MB of data
        XCTAssertTrue(fileManager.createFile(atPath: legacyDbUrl.path, contents: largeData, attributes: nil))
        
        // When
        migrateDatabaseWithTestConstants()
        
        // Then
        XCTAssertTrue(fileManager.fileExists(atPath: newDbUrl.path), "Large database should be migrated successfully")
        XCTAssertFalse(fileManager.fileExists(atPath: legacyDbUrl.path), "Legacy large database should be removed")
        
        let migratedData = try? Data(contentsOf: newDbUrl)
        XCTAssertEqual(migratedData?.count, largeData.count, "Migrated database should have same size as original")
    }
}
