//
/*
 Copyright 2023 Adobe. All rights reserved.
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
@testable import AEPIdentity
@testable import AEPLifecycle
import AEPServicesMocks

class UserDefaultMigratorTests: XCTestCase {
    private var mockDataStore: MockDataStore {
        return ServiceProvider.shared.namedKeyValueService as! MockDataStore
    }
    private var defaults: UserDefaults {
        if let appGroup = ServiceProvider.shared.namedKeyValueService.getAppGroup(), !appGroup.isEmpty {
            return UserDefaults(suiteName: appGroup) ?? UserDefaults.standard
        }
        
        return UserDefaults.standard
    }
    
    private func keyWithPrefix(datastoreName: String, key: String) -> String {
        return "Adobe.\(datastoreName).\(key)"
    }
    
    private func setInstallDate(date: Date) {
        let installDateKey = keyWithPrefix(datastoreName: UserDefaultMigratorConstants.Lifecycle.DATASTORE_NAME, key: UserDefaultMigratorConstants.Lifecycle.DataStoreKeys.INSTALL_DATE.rawValue)
        defaults.set(date, forKey: installDateKey)
    }
    
    private func removeInstallDate() {
        let installDateKey = keyWithPrefix(datastoreName: UserDefaultMigratorConstants.Lifecycle.DATASTORE_NAME, key: UserDefaultMigratorConstants.Lifecycle.DataStoreKeys.INSTALL_DATE.rawValue)
        defaults.removeObject(forKey: installDateKey)
    }
    
    override func setUp() {
        ServiceProvider.shared.namedKeyValueService = MockDataStore()
        let date = Date()
        setInstallDate(date: date)
    }

    func testNoMigrationIfAlreadyMigrated() {
        removeInstallDate()
        let configurationStoreName = UserDefaultMigratorConstants.Configuration.DATASTORE_NAME
        typealias configurationKeys = UserDefaultMigratorConstants.Configuration.DataStoreKeys
        let configMap = "{\"global.privacy\": \"optedout\"}"
        let appID = "appID"
        let configMapKey = keyWithPrefix(datastoreName: configurationStoreName, key: configurationKeys.OVERRIDDEN_MAP.rawValue)
        let appIDKey = keyWithPrefix(datastoreName: configurationStoreName, key: configurationKeys.APP_ID.rawValue)
        defaults.set(configMap, forKey: configMapKey)
        defaults.set(appID, forKey: appIDKey)
        
        UserDefaultsMigrator().migrate()
        XCTAssertTrue(mockDataStore.dict.isEmpty)
    }
    
    func testConfigurationMigration() {
        let configurationStoreName = UserDefaultMigratorConstants.Configuration.DATASTORE_NAME
        typealias configurationKeys = UserDefaultMigratorConstants.Configuration.DataStoreKeys
        let configMap = "{\"global.privacy\": \"optedout\"}"
        let appID = "appID"
        let configMapKey = keyWithPrefix(datastoreName: configurationStoreName, key: configurationKeys.OVERRIDDEN_MAP.rawValue)
        let appIDKey = keyWithPrefix(datastoreName: configurationStoreName, key: configurationKeys.APP_ID.rawValue)
        defaults.set(configMap, forKey: configMapKey)
        defaults.set(appID, forKey: appIDKey)
        
        UserDefaultsMigrator().migrate()
        
        XCTAssertEqual(mockDataStore.dict[configurationKeys.OVERRIDDEN_MAP.rawValue] as? String, configMap)
        XCTAssertEqual(mockDataStore.dict[configurationKeys.APP_ID.rawValue] as? String, appID)
        XCTAssertNil(defaults.object(forKey: configMapKey))
        XCTAssertNil(defaults.object(forKey: appIDKey))
    }
    
    func testIdentityMigration() {
        let identityStoreName = UserDefaultMigratorConstants.Identity.DATASTORE_NAME
        typealias identityKeys = UserDefaultMigratorConstants.Identity.DataStoreKeys
        var properties = IdentityProperties()
        properties.ecid = ECID()
        properties.advertisingIdentifier = "test-ad-id"
        properties.pushIdentifier = "test-push-id"
        properties.blob = "test-blob"
        properties.locationHint = "test-location-hint"
        properties.customerIds = [CustomIdentity(origin: "test-origin", type: "test-type", identifier: "test-identifier", authenticationState: .authenticated)]
        properties.lastSync = Date()
        
        let identityPropertyKey = keyWithPrefix(datastoreName: identityStoreName, key: identityKeys.IDENTITY_PROPERTIES.rawValue)
        let identityPushEnabledKey = keyWithPrefix(datastoreName: identityStoreName, key: identityKeys.PUSH_ENABLED.rawValue)
        let identityAnalyticsPushEnabledKey = keyWithPrefix(datastoreName: identityStoreName, key: identityKeys.ANALYTICS_PUSH_ENABLED.rawValue)
        let encoder = JSONEncoder()
        if let encodedValue = try? encoder.encode(properties), let encodedString = String(data: encodedValue, encoding: .utf8) {
            defaults.set(encodedString, forKey: identityPropertyKey)
        }
        defaults.set(true, forKey: identityPushEnabledKey)
        defaults.set(false, forKey: identityAnalyticsPushEnabledKey)
        
        UserDefaultsMigrator().migrate()
        
        var setProperties: IdentityProperties?
        if let savedString = mockDataStore.dict[identityKeys.IDENTITY_PROPERTIES.rawValue] as? String, let savedData = savedString.data(using: .utf8) {
            setProperties =  try? JSONDecoder().decode(IdentityProperties.self, from: savedData)
        }
        XCTAssertEqual(setProperties?.ecid, properties.ecid)
        XCTAssertEqual(setProperties?.advertisingIdentifier, properties.advertisingIdentifier)
        XCTAssertEqual(setProperties?.pushIdentifier, properties.pushIdentifier)
        XCTAssertEqual(setProperties?.blob, properties.blob)
        XCTAssertEqual(setProperties?.locationHint, properties.locationHint)
        XCTAssertEqual(setProperties?.customerIds, properties.customerIds)
        XCTAssertEqual(setProperties?.lastSync, properties.lastSync)
        XCTAssertTrue(mockDataStore.dict[identityKeys.PUSH_ENABLED.rawValue] as! Bool)
        XCTAssertFalse(mockDataStore.dict[identityKeys.ANALYTICS_PUSH_ENABLED.rawValue] as! Bool)
        XCTAssertNil(defaults.object(forKey: identityPropertyKey))
        XCTAssertNil(defaults.object(forKey: identityPushEnabledKey))
        XCTAssertNil(defaults.object(forKey: identityAnalyticsPushEnabledKey))
    }
    
    func testLifecycleMigration() {
        removeInstallDate()
        
        let mockDate = Date()
        setInstallDate(date: mockDate)
        let lifecycleStoreName = UserDefaultMigratorConstants.Lifecycle.DATASTORE_NAME
        typealias lifecycleKeys = UserDefaultMigratorConstants.Lifecycle.DataStoreKeys
        let installDateKey = keyWithPrefix(datastoreName: lifecycleStoreName, key: lifecycleKeys.INSTALL_DATE.rawValue)
        let lastLaunchDateKey = keyWithPrefix(datastoreName: lifecycleStoreName, key: lifecycleKeys.LAST_LAUNCH_DATE.rawValue)
        let upgradeDateKey = keyWithPrefix(datastoreName: lifecycleStoreName, key: lifecycleKeys.UPGRADE_DATE.rawValue)
        let persistedContextKey = keyWithPrefix(datastoreName: lifecycleStoreName, key: lifecycleKeys.PERSISTED_CONTEXT.rawValue)
        let lifecycleDataKey = keyWithPrefix(datastoreName: lifecycleStoreName, key: lifecycleKeys.LIFECYCLE_DATA.rawValue)
        let lastVersionKey = keyWithPrefix(datastoreName: lifecycleStoreName, key: lifecycleKeys.LAST_VERSION.rawValue)
        let v2LastVersionKey = keyWithPrefix(datastoreName: lifecycleStoreName, key: lifecycleKeys.V2_LAST_VERSION.rawValue)
        let v2AppCloseDateKey = keyWithPrefix(datastoreName: lifecycleStoreName, key: lifecycleKeys.V2_APP_CLOSE_DATE.rawValue)
        let v2AppPauseDateKey = keyWithPrefix(datastoreName: lifecycleStoreName, key: lifecycleKeys.V2_APP_PAUSE_DATE.rawValue)
        let v2AppStartDateKey = keyWithPrefix(datastoreName: lifecycleStoreName, key: lifecycleKeys.V2_APP_START_DATE.rawValue)
        let launchesSinceUpgradeKey = keyWithPrefix(datastoreName: lifecycleStoreName, key: lifecycleKeys.LAUNCHES_SINCE_UPGRADE.rawValue)
        
        let launchesSinceUpgrade: Int = 1
        var persistedContext = LifecyclePersistedContext()
        persistedContext.appId = "appID"
        persistedContext.launches = 5
        persistedContext.osVersion = "1.0.0"
        persistedContext.pauseDate = mockDate
        persistedContext.startDate = mockDate
        persistedContext.successfulClose = true
        let encoder = JSONEncoder()
        if let encodedValue = try? encoder.encode(persistedContext), let encodedString = String(data: encodedValue, encoding: .utf8) {
            defaults.set(encodedString, forKey: persistedContextKey)
        }
        var lifecycleMetrics = LifecycleMetrics()
        lifecycleMetrics.appId = "appID"
        var lifecycleContextData = LifecycleContextData()
        lifecycleContextData.sessionContextData = ["contextDataKey": "contextDataVal"]
        lifecycleContextData.additionalContextData = ["additionalContextDataKey": "additionalContextDataVal"]
        lifecycleContextData.lifecycleMetrics = lifecycleMetrics
        lifecycleContextData.advertisingIdentifier = "advertisingID"
        if let encodedValue = try? encoder.encode(lifecycleContextData), let encodedString = String(data: encodedValue, encoding: .utf8) {
            defaults.set(encodedString, forKey: lifecycleDataKey)
        }
        let lastVersion = "1.0.0"
        defaults.set(lastVersion, forKey: lastVersionKey)
        defaults.set(lastVersion, forKey: v2LastVersionKey)
        defaults.set(mockDate.timeIntervalSince1970, forKey: upgradeDateKey)
        defaults.set(mockDate.timeIntervalSince1970, forKey: lastLaunchDateKey)
        defaults.set(mockDate.timeIntervalSince1970, forKey: v2AppCloseDateKey)
        defaults.set(mockDate.timeIntervalSince1970, forKey: v2AppPauseDateKey)
        defaults.set(mockDate.timeIntervalSince1970, forKey: v2AppStartDateKey)
        defaults.set(launchesSinceUpgrade, forKey: launchesSinceUpgradeKey)
        
        UserDefaultsMigrator().migrate()
        
        var setPersistedContext: LifecyclePersistedContext?
        var setLifecycleData: LifecycleContextData?
        let jsonDecoder = JSONDecoder()
        if let persistedContextString = mockDataStore.dict[lifecycleKeys.PERSISTED_CONTEXT.rawValue] as? String, let persistedContextData = persistedContextString.data(using: .utf8) {
            setPersistedContext =  try? jsonDecoder.decode(LifecyclePersistedContext.self, from: persistedContextData)
        }
        
        if let lifecycleDataString = mockDataStore.dict[lifecycleKeys.LIFECYCLE_DATA.rawValue] as? String, let lifecycleDataAsData = lifecycleDataString.data(using: .utf8) {
            setLifecycleData = try? jsonDecoder.decode(LifecycleContextData.self, from: lifecycleDataAsData)
        }
        
        XCTAssertEqual(setPersistedContext?.appId, persistedContext.appId)
        XCTAssertEqual(setPersistedContext?.launches, persistedContext.launches)
        XCTAssertEqual(setPersistedContext?.osVersion, persistedContext.osVersion)
        XCTAssertEqual(setPersistedContext?.pauseDate, persistedContext.pauseDate)
        XCTAssertEqual(setPersistedContext?.startDate, persistedContext.startDate)
        XCTAssertEqual(setPersistedContext?.successfulClose, persistedContext.successfulClose)
        XCTAssertEqual(setLifecycleData?.advertisingIdentifier, lifecycleContextData.advertisingIdentifier)
        XCTAssertEqual(setLifecycleData?.lifecycleMetrics, lifecycleContextData.lifecycleMetrics)
        XCTAssertEqual(mockDataStore.dict[lifecycleKeys.LAST_LAUNCH_DATE.rawValue] as? Double, mockDate.timeIntervalSince1970)
        XCTAssertEqual(mockDataStore.dict[lifecycleKeys.UPGRADE_DATE.rawValue] as? Double, mockDate.timeIntervalSince1970)
        XCTAssertEqual(mockDataStore.dict[lifecycleKeys.LAUNCHES_SINCE_UPGRADE.rawValue] as? Int, launchesSinceUpgrade)
        XCTAssertEqual(mockDataStore.dict[lifecycleKeys.LAST_VERSION.rawValue] as? String, lastVersion)
        XCTAssertEqual(mockDataStore.dict[lifecycleKeys.V2_LAST_VERSION.rawValue] as? String, lastVersion)
        XCTAssertEqual(mockDataStore.dict[lifecycleKeys.V2_APP_START_DATE.rawValue] as? Double, mockDate.timeIntervalSince1970)
        XCTAssertEqual(mockDataStore.dict[lifecycleKeys.V2_APP_PAUSE_DATE.rawValue] as? Double, mockDate.timeIntervalSince1970)
        XCTAssertEqual(mockDataStore.dict[lifecycleKeys.V2_APP_CLOSE_DATE.rawValue] as? Double, mockDate.timeIntervalSince1970)
        
        XCTAssertNil(defaults.object(forKey: installDateKey))
        XCTAssertNil(defaults.object(forKey: lastLaunchDateKey))
        XCTAssertNil(defaults.object(forKey: upgradeDateKey))
        XCTAssertNil(defaults.object(forKey: launchesSinceUpgradeKey))
        XCTAssertNil(defaults.object(forKey: persistedContextKey))
        XCTAssertNil(defaults.object(forKey: lifecycleDataKey))
        XCTAssertNil(defaults.object(forKey: lastVersionKey))
        XCTAssertNil(defaults.object(forKey: v2LastVersionKey))
        XCTAssertNil(defaults.object(forKey: v2AppStartDateKey))
        XCTAssertNil(defaults.object(forKey: v2AppPauseDateKey))
        XCTAssertNil(defaults.object(forKey: v2AppCloseDateKey))
    }
    
    func testAssuranceMigration() {
        typealias assuranceKeys = UserDefaultMigratorConstants.Assurance.DataStoreKeys
        let storeName = UserDefaultMigratorConstants.Assurance.DATASTORE_NAME
        let clientIDKey = keyWithPrefix(datastoreName: storeName, key: assuranceKeys.CLIENT_ID.rawValue)
        let environmentKey = keyWithPrefix(datastoreName: storeName, key: assuranceKeys.ENVIRONMENT.rawValue)
        let socketURLKey = keyWithPrefix(datastoreName: storeName, key: assuranceKeys.SOCKET_URL.rawValue)
        let modifiedConfigKey = keyWithPrefix(datastoreName: storeName, key: assuranceKeys.MODIFIED_CONFIG_KEYS.rawValue)
        
        let clientID = "clientID"
        let environment = "test.environment"
        let socketURL = "socket.url"
        let modifiedConfigKeys = ["test", "test2"]
        
        defaults.set(clientID, forKey: clientIDKey)
        defaults.set(environment, forKey: environmentKey)
        defaults.set(socketURL, forKey: socketURLKey)
        defaults.set(modifiedConfigKeys, forKey: modifiedConfigKey)
        
        UserDefaultsMigrator().migrate()
        
        XCTAssertEqual(mockDataStore.dict[assuranceKeys.CLIENT_ID.rawValue] as? String, clientID)
        XCTAssertEqual(mockDataStore.dict[assuranceKeys.ENVIRONMENT.rawValue] as? String, environment)
        XCTAssertEqual(mockDataStore.dict[assuranceKeys.SOCKET_URL.rawValue] as? String, socketURL)
        XCTAssertEqual(mockDataStore.dict[assuranceKeys.MODIFIED_CONFIG_KEYS.rawValue] as? [String], modifiedConfigKeys)
        
        XCTAssertNil(defaults.object(forKey: clientIDKey))
        XCTAssertNil(defaults.object(forKey: environmentKey))
        XCTAssertNil(defaults.object(forKey: socketURLKey))
        XCTAssertNil(defaults.object(forKey: modifiedConfigKey))

    }
    
    func testAnalyticsMigration() {
        let storeName = UserDefaultMigratorConstants.Analytics.DATASTORE_NAME
        typealias analyticsKeys = UserDefaultMigratorConstants.Analytics.DataStoreKeys
        let lastHitTSKey = keyWithPrefix(datastoreName: storeName, key: analyticsKeys.LAST_HIT_TS.rawValue)
        let 
    }
    
    func testAudienceMigration() {
        
    }
    
    func testTargetMigration() {
        
    }
    
    func testCampaignMigration() {
        
    }
    
    func testCampaignClassicMigration() {
        
    }
    
    func testPlacesMigration() {
        
    }
    
    func testUserProfileMigration() {
        
    }
    
    func testEdgeMigration() {
        
    }
    
    func testEdgeIdentityMigration() {
        
    }
    
    func testEdgeConsentMigration() {
        
    }
}
