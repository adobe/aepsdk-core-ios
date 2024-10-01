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
    
    private func removeMigrationComplete() {
        mockDataStore.remove(collectionName: UserDefaultMigratorConstants.MIGRATION_STORE_NAME, key: UserDefaultMigratorConstants.MIGRATION_COMPLETE)
    }
    
    private func setMigrationComplete() {
        mockDataStore.set(collectionName: UserDefaultMigratorConstants.MIGRATION_STORE_NAME, key: UserDefaultMigratorConstants.MIGRATION_COMPLETE, value: true)
    }
    
    override func setUp() {
        ServiceProvider.shared.namedKeyValueService = MockDataStore()
        removeMigrationComplete()
    }

    func testNoMigrationIfAlreadyMigrated() {
        setMigrationComplete()
        let configurationStoreName = UserDefaultMigratorConstants.Configuration.DATASTORE_NAME
        typealias configurationKeys = UserDefaultMigratorConstants.Configuration.DataStoreKeys
        let configMap = "{\"global.privacy\": \"optedout\"}"
        let appID = "appID"
        let configMapKey = keyWithPrefix(datastoreName: configurationStoreName, key: configurationKeys.OVERRIDDEN_MAP.rawValue)
        let appIDKey = keyWithPrefix(datastoreName: configurationStoreName, key: configurationKeys.APP_ID.rawValue)
        defaults.set(configMap, forKey: configMapKey)
        defaults.set(appID, forKey: appIDKey)
        
        UserDefaultsMigrator().migrate()
        XCTAssertTrue(mockDataStore.dict.count == 1)
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
        let identityStoreName = IdentityConstants.DATASTORE_NAME
        typealias identityKeys = IdentityConstants.DataStoreKeys
        var properties = IdentityProperties()
        properties.ecid = ECID()
        properties.advertisingIdentifier = "test-ad-id"
        properties.pushIdentifier = "test-push-id"
        properties.blob = "test-blob"
        properties.locationHint = "test-location-hint"
        properties.customerIds = [CustomIdentity(origin: "test-origin", type: "test-type", identifier: "test-identifier", authenticationState: .authenticated)]
        properties.lastSync = Date()
        
        let identityPropertyKey = keyWithPrefix(datastoreName: identityStoreName, key: identityKeys.IDENTITY_PROPERTIES)
        let identityPushEnabledKey = keyWithPrefix(datastoreName: identityStoreName, key: identityKeys.PUSH_ENABLED)
        let identityAnalyticsPushEnabledKey = keyWithPrefix(datastoreName: identityStoreName, key: identityKeys.ANALYTICS_PUSH_SYNC)
        let encoder = JSONEncoder()
        if let encodedValue = try? encoder.encode(properties) {
            defaults.set(encodedValue, forKey: identityPropertyKey)
        }
        defaults.set(true, forKey: identityPushEnabledKey)
        defaults.set(false, forKey: identityAnalyticsPushEnabledKey)
        
        UserDefaultsMigrator().migrate()
        
        var setProperties: IdentityProperties?
        if let savedString = mockDataStore.dict[identityKeys.IDENTITY_PROPERTIES] as? String, let savedData = savedString.data(using: .utf8) {
            setProperties =  try? JSONDecoder().decode(IdentityProperties.self, from: savedData)
        }
        XCTAssertEqual(setProperties?.ecid, properties.ecid)
        XCTAssertEqual(setProperties?.advertisingIdentifier, properties.advertisingIdentifier)
        XCTAssertEqual(setProperties?.pushIdentifier, properties.pushIdentifier)
        XCTAssertEqual(setProperties?.blob, properties.blob)
        XCTAssertEqual(setProperties?.locationHint, properties.locationHint)
        XCTAssertEqual(setProperties?.customerIds, properties.customerIds)
        XCTAssertEqual(setProperties?.lastSync, properties.lastSync)
        XCTAssertTrue(mockDataStore.dict[identityKeys.PUSH_ENABLED] as? Bool ?? false)
        XCTAssertFalse(mockDataStore.dict[identityKeys.ANALYTICS_PUSH_SYNC] as? Bool ?? true)
        XCTAssertNil(defaults.object(forKey: identityPropertyKey))
        XCTAssertNil(defaults.object(forKey: identityPushEnabledKey))
        XCTAssertNil(defaults.object(forKey: identityAnalyticsPushEnabledKey))
    }
    
    func testLifecycleMigration() {
        let mockDate = Date()
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
        if let encodedValue = try? encoder.encode(persistedContext) {
            defaults.set(encodedValue, forKey: persistedContextKey)
        }
        var lifecycleMetrics = LifecycleMetrics()
        lifecycleMetrics.appId = "appID"
        var lifecycleContextData = LifecycleContextData()
        lifecycleContextData.sessionContextData = ["contextDataKey": "contextDataVal"]
        lifecycleContextData.additionalContextData = ["additionalContextDataKey": "additionalContextDataVal"]
        lifecycleContextData.lifecycleMetrics = lifecycleMetrics
        lifecycleContextData.advertisingIdentifier = "advertisingID"
        if let encodedValue = try? encoder.encode(lifecycleContextData) {
            defaults.set(encodedValue, forKey: lifecycleDataKey)
        }
        let lastVersion = "1.0.0"
        defaults.set(mockDate, forKey: installDateKey)
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
        let aidKey = keyWithPrefix(datastoreName: storeName, key: analyticsKeys.AID.rawValue)
        let vidKey = keyWithPrefix(datastoreName: storeName, key: analyticsKeys.VID.rawValue)
        let dataMigratedKey = keyWithPrefix(datastoreName: storeName, key: analyticsKeys.DATA_MIGRATED.rawValue)
        let lastHitTS = 1
        let aid = "aid"
        let vid = "vid"
        let dataMigrated = true
        
        defaults.set(lastHitTS, forKey: lastHitTSKey)
        defaults.set(aid, forKey: aidKey)
        defaults.set(vid, forKey: vidKey)
        defaults.set(dataMigrated, forKey: dataMigratedKey)
        
        UserDefaultsMigrator().migrate()
        
        XCTAssertEqual(mockDataStore.dict[analyticsKeys.LAST_HIT_TS.rawValue] as? Int, lastHitTS)
        XCTAssertEqual(mockDataStore.dict[analyticsKeys.AID.rawValue] as? String, aid)
        XCTAssertEqual(mockDataStore.dict[analyticsKeys.VID.rawValue] as? String, vid)
        XCTAssertEqual(mockDataStore.dict[analyticsKeys.DATA_MIGRATED.rawValue] as? Bool, dataMigrated)
        
        XCTAssertNil(defaults.object(forKey: lastHitTSKey))
        XCTAssertNil(defaults.object(forKey: aidKey))
        XCTAssertNil(defaults.object(forKey: vidKey))
        XCTAssertNil(defaults.object(forKey: dataMigratedKey))
    }
    
    func testAudienceMigration() {
        let storeName = UserDefaultMigratorConstants.Audience.DATASTORE_NAME
        typealias audienceKeys = UserDefaultMigratorConstants.Audience.DataStoreKeys
        let userProfileKey = keyWithPrefix(datastoreName: storeName, key: audienceKeys.USER_PROFILE.rawValue)
        let userIDKey = keyWithPrefix(datastoreName: storeName, key: audienceKeys.USER_ID.rawValue)
        
        let userProfile = ["test": "profiles"]
        let userID = "userID"
        
        defaults.set(userProfile, forKey: userProfileKey)
        defaults.set(userID, forKey: userIDKey)
        
        UserDefaultsMigrator().migrate()
        
        XCTAssertEqual(mockDataStore.dict[audienceKeys.USER_PROFILE.rawValue] as? [String: String], userProfile)
        XCTAssertEqual(mockDataStore.dict[audienceKeys.USER_ID.rawValue] as? String, userID)
        
        XCTAssertNil(defaults.object(forKey: userProfileKey))
        XCTAssertNil(defaults.object(forKey: userIDKey))
    }
    
    func testTargetMigration() {
        let storeName = UserDefaultMigratorConstants.Target.DATASTORE_NAME
        typealias targetKeys = UserDefaultMigratorConstants.Target.DataStoreKeys
        let sessionTimestampKey = keyWithPrefix(datastoreName: storeName, key: targetKeys.SESSION_TIMESTAMP.rawValue)
        let sessionIDKey = keyWithPrefix(datastoreName: storeName, key: targetKeys.SESSION_ID.rawValue)
        let tntIDKey = keyWithPrefix(datastoreName: storeName, key: targetKeys.TNT_ID.rawValue)
        let edgeHostKey = keyWithPrefix(datastoreName: storeName, key: targetKeys.EDGE_HOST.rawValue)
        let thirdPartyIDKey = keyWithPrefix(datastoreName: storeName, key: targetKeys.THIRD_PARTY_ID.rawValue)
        let sessionTimestamp = Date()
        let sessionID = "sessionID"
        let tntID = "tntID"
        let edgeHost = "edge.host"
        let thirdPartyID = "thirdPartyID"
        
        defaults.set(sessionTimestamp.timeIntervalSince1970, forKey: sessionTimestampKey)
        defaults.set(sessionID, forKey: sessionIDKey)
        defaults.set(tntID, forKey: tntIDKey)
        defaults.set(edgeHost, forKey: edgeHostKey)
        defaults.set(thirdPartyID, forKey: thirdPartyIDKey)
        
        UserDefaultsMigrator().migrate()
        
        XCTAssertEqual(mockDataStore.dict[targetKeys.SESSION_TIMESTAMP.rawValue] as? Double, sessionTimestamp.timeIntervalSince1970)
        XCTAssertEqual(mockDataStore.dict[targetKeys.SESSION_ID.rawValue] as? String, sessionID)
        XCTAssertEqual(mockDataStore.dict[targetKeys.TNT_ID.rawValue] as? String, tntID)
        XCTAssertEqual(mockDataStore.dict[targetKeys.EDGE_HOST.rawValue] as? String, edgeHost)
        XCTAssertEqual(mockDataStore.dict[targetKeys.THIRD_PARTY_ID.rawValue] as? String, thirdPartyID)
        
        XCTAssertNil(defaults.object(forKey: sessionTimestampKey))
        XCTAssertNil(defaults.object(forKey: sessionIDKey))
        XCTAssertNil(defaults.object(forKey: tntIDKey))
        XCTAssertNil(defaults.object(forKey: edgeHostKey))
        XCTAssertNil(defaults.object(forKey: thirdPartyIDKey))
    }
    
    func testCampaignMigration() {
        let storeName = UserDefaultMigratorConstants.Campaign.DATASTORE_NAME
        typealias campaignKeys = UserDefaultMigratorConstants.Campaign.DataStoreKeys
        
        let remoteURLKey = keyWithPrefix(datastoreName: storeName, key: campaignKeys.REMOTE_URL.rawValue)
        let ecidKey = keyWithPrefix(datastoreName: storeName, key: campaignKeys.ECID.rawValue)
        let registrationTSKey = keyWithPrefix(datastoreName: storeName, key: campaignKeys.REGISTRATION_TS.rawValue)
        
        let remoteURL = "remote.url"
        let ecid = "ecid"
        let registrationTS = Date().timeIntervalSince1970
        
        defaults.set(remoteURL, forKey: remoteURLKey)
        defaults.set(ecid, forKey: ecidKey)
        defaults.set(registrationTS, forKey: registrationTSKey)
        
        UserDefaultsMigrator().migrate()
        
        XCTAssertEqual(mockDataStore.dict[campaignKeys.REMOTE_URL.rawValue] as? String, remoteURL)
        XCTAssertEqual(mockDataStore.dict[campaignKeys.ECID.rawValue] as? String, ecid)
        XCTAssertEqual(mockDataStore.dict[campaignKeys.REGISTRATION_TS.rawValue] as? Double, registrationTS)
        
        XCTAssertNil(defaults.object(forKey: remoteURLKey))
        XCTAssertNil(defaults.object(forKey: ecidKey))
        XCTAssertNil(defaults.object(forKey: registrationTSKey))
    }
    
    func testCampaignClassicMigration() {
        let storeName = UserDefaultMigratorConstants.CampaignClassic.DATASTORE_NAME
        let tokenHashKey = keyWithPrefix(datastoreName: storeName, key: UserDefaultMigratorConstants.CampaignClassic.DataStoreKeys.TOKEN_HASH.rawValue)
        
        let tokenHash = "hash"
        
        defaults.set(tokenHash, forKey: tokenHashKey)
        
        UserDefaultsMigrator().migrate()
        
        XCTAssertEqual(mockDataStore.dict[UserDefaultMigratorConstants.CampaignClassic.DataStoreKeys.TOKEN_HASH.rawValue] as? String, tokenHash)
        
        XCTAssertNil(defaults.object(forKey: tokenHashKey))
    }
    
    func testPlacesMigration() {
        let storeName = UserDefaultMigratorConstants.Places.DATASTORE_NAME
        typealias storeKeys = UserDefaultMigratorConstants.Places.DataStoreKeys
        
        let accuracyKey = keyWithPrefix(datastoreName: storeName, key: storeKeys.ACCURACY.rawValue) // String
        let authStatusKey = keyWithPrefix(datastoreName: storeName, key: storeKeys.AUTH_STATUS.rawValue) // String
        let currentPOIKey = keyWithPrefix(datastoreName: storeName, key: storeKeys.CURRENT_POI.rawValue) // String
        let lastEnteredPOIKey = keyWithPrefix(datastoreName: storeName, key: storeKeys.LAST_ENTERED_POI.rawValue) // String
        let lastExitedPOIKey = keyWithPrefix(datastoreName: storeName, key: storeKeys.LAST_EXITED_POI.rawValue) // String
        let lastKnownLatKey = keyWithPrefix(datastoreName: storeName, key: storeKeys.LAST_KNOWN_LATITUDE.rawValue) // Double
        let lastKnownLongKey = keyWithPrefix(datastoreName: storeName, key: storeKeys.LAST_KNOWN_LONGITUDE.rawValue) // Double
        let membershipKey = keyWithPrefix(datastoreName: storeName, key: storeKeys.MEMBERSHIP.rawValue) // TimeInterval
        let nearbyPOIsKey = keyWithPrefix(datastoreName: storeName, key: storeKeys.NEARBY_POIS.rawValue) // [String: String]
        let userWithinPOIsKey = keyWithPrefix(datastoreName: storeName, key: storeKeys.USER_WITHIN_POIS.rawValue) // [String: String]
        
        let accuracy = "accurate"
        let authStatus = "authorized"
        let currentPOI = "current poi"
        let lastEnteredPOI = "last entered poi"
        let lastExitedPOI = "last exited poi"
        let lastKnownLat: Double = 12.345
        let lastKnownLong: Double = 67.891
        let membershipValidUntil = Date().timeIntervalSince1970
        let nearbyPOIs = ["nearby": "pois"]
        let userWithinPOIs = ["user": "within"]
        
        defaults.set(accuracy, forKey: accuracyKey)
        defaults.set(authStatus, forKey: authStatusKey)
        defaults.set(currentPOI, forKey: currentPOIKey)
        defaults.set(lastEnteredPOI, forKey: lastEnteredPOIKey)
        defaults.set(lastExitedPOI, forKey: lastExitedPOIKey)
        defaults.set(lastKnownLat, forKey: lastKnownLatKey)
        defaults.set(lastKnownLong, forKey: lastKnownLongKey)
        defaults.set(membershipValidUntil, forKey: membershipKey)
        defaults.set(nearbyPOIs, forKey: nearbyPOIsKey)
        defaults.set(userWithinPOIs, forKey: userWithinPOIsKey)
        
        UserDefaultsMigrator().migrate()
        
        XCTAssertEqual(mockDataStore.dict[storeKeys.ACCURACY.rawValue] as? String, accuracy)
        XCTAssertEqual(mockDataStore.dict[storeKeys.AUTH_STATUS.rawValue] as? String, authStatus)
        XCTAssertEqual(mockDataStore.dict[storeKeys.CURRENT_POI.rawValue] as? String, currentPOI)
        XCTAssertEqual(mockDataStore.dict[storeKeys.LAST_ENTERED_POI.rawValue] as? String, lastEnteredPOI)
        XCTAssertEqual(mockDataStore.dict[storeKeys.LAST_EXITED_POI.rawValue] as? String, lastExitedPOI)
        XCTAssertEqual(mockDataStore.dict[storeKeys.LAST_KNOWN_LATITUDE.rawValue] as? Double, lastKnownLat)
        XCTAssertEqual(mockDataStore.dict[storeKeys.LAST_KNOWN_LONGITUDE.rawValue] as? Double, lastKnownLong)
        XCTAssertEqual(mockDataStore.dict[storeKeys.MEMBERSHIP.rawValue] as? Double, membershipValidUntil)
        XCTAssertEqual(mockDataStore.dict[storeKeys.NEARBY_POIS.rawValue] as? [String: String], nearbyPOIs)
        XCTAssertEqual(mockDataStore.dict[storeKeys.USER_WITHIN_POIS.rawValue] as? [String: String], userWithinPOIs)
        
        XCTAssertNil(defaults.object(forKey: accuracyKey))
        XCTAssertNil(defaults.object(forKey: authStatusKey))
        XCTAssertNil(defaults.object(forKey: currentPOIKey))
        XCTAssertNil(defaults.object(forKey: lastEnteredPOIKey))
        XCTAssertNil(defaults.object(forKey: lastExitedPOIKey))
        XCTAssertNil(defaults.object(forKey: lastKnownLatKey))
        XCTAssertNil(defaults.object(forKey: lastKnownLongKey))
        XCTAssertNil(defaults.object(forKey: membershipKey))
        XCTAssertNil(defaults.object(forKey: nearbyPOIsKey))
        XCTAssertNil(defaults.object(forKey: userWithinPOIsKey))
    }
    
    func testUserProfileMigration() {
        let storeName = UserDefaultMigratorConstants.UserProfile.DATASTORE_NAME
        
        let attributeKey = keyWithPrefix(datastoreName: storeName, key: UserDefaultMigratorConstants.UserProfile.DataStoreKeys.ATTRIBUTES.rawValue)
        let attributes = ["attributeKey": "attributeValue"]
        
        defaults.set(attributes, forKey: attributeKey)
        
        UserDefaultsMigrator().migrate()
        
        XCTAssertEqual(mockDataStore.dict[UserDefaultMigratorConstants.UserProfile.DataStoreKeys.ATTRIBUTES.rawValue] as? [String: String], attributes)
        
        XCTAssertNil(defaults.object(forKey: attributeKey))
        
    }
    
    func testEdgeMigration() {
        let storeName = UserDefaultMigratorConstants.Edge.DATASTORE_NAME
        typealias storeKeys = UserDefaultMigratorConstants.Edge.EdgeDataStoreKeys
        
        let resetIdentitiesDateKey = keyWithPrefix(datastoreName: storeName, key: storeKeys.RESET_IDENTITIES_DATE.rawValue)
        let edgePropertiesKey = keyWithPrefix(datastoreName: storeName, key: storeKeys.EDGE_PROPERTIES.rawValue)
        
        let resetIdentitiesDate = Date().timeIntervalSince1970
        let edgeProperties = ["locationHint": "hint"]
        
        defaults.set(resetIdentitiesDate, forKey: resetIdentitiesDateKey)
        defaults.set(edgeProperties, forKey: edgePropertiesKey)
        
        UserDefaultsMigrator().migrate()
        
        XCTAssertEqual(mockDataStore.dict[storeKeys.RESET_IDENTITIES_DATE.rawValue] as? Double, resetIdentitiesDate)
        XCTAssertEqual(mockDataStore.dict[storeKeys.EDGE_PROPERTIES.rawValue] as? [String: String], edgeProperties)
        
        XCTAssertNil(defaults.object(forKey: resetIdentitiesDateKey))
        XCTAssertNil(defaults.object(forKey: edgePropertiesKey))
    }
    
    func testEdgePayloadMigration() {
        let payloadStoreName = UserDefaultMigratorConstants.Edge.PAYLOAD_DATASTORE_NAME
        let payloadKey = keyWithPrefix(datastoreName: payloadStoreName, key: UserDefaultMigratorConstants.Edge.EdgePayloadStoreKeys.STORE_PAYLOADS.rawValue)
        
        let payload = ["payloadKey": "payloadValue"]
        
        defaults.set(payload, forKey: payloadKey)
        
        UserDefaultsMigrator().migrate()
        
        XCTAssertEqual(mockDataStore.dict[UserDefaultMigratorConstants.Edge.EdgePayloadStoreKeys.STORE_PAYLOADS.rawValue] as? [String: String], payload)
        XCTAssertNil(defaults.object(forKey: payloadKey))
    }
    
    func testEdgeIdentityMigration() {
        let storeName = UserDefaultMigratorConstants.EdgeIdentity.DATASTORE_NAME
        let identityPropertiesKey = keyWithPrefix(datastoreName: storeName, key: UserDefaultMigratorConstants.EdgeIdentity.DataStoreKeys.IDENTITY_PROPERTIES.rawValue)
        let identityProperties = ["identity": "properties"]
        defaults.set(identityProperties, forKey: identityPropertiesKey)
        
        UserDefaultsMigrator().migrate()
        
        XCTAssertEqual(mockDataStore.dict[UserDefaultMigratorConstants.EdgeIdentity.DataStoreKeys.IDENTITY_PROPERTIES.rawValue] as? [String: String], identityProperties)
        XCTAssertNil(defaults.object(forKey: identityPropertiesKey))
    }
    
    func testEdgeConsentMigration() {
        let storeName = UserDefaultMigratorConstants.EdgeConsent.DATASTORE_NAME
        let consentPreferencesKey = keyWithPrefix(datastoreName: storeName, key: UserDefaultMigratorConstants.EdgeConsent.DataStoreKeys.CONSENT_PREFERENCES.rawValue)
        
        let consentPreferences = ["consent": "preferences"]
        
        defaults.set(consentPreferences, forKey: consentPreferencesKey)
        
        UserDefaultsMigrator().migrate()
        
        XCTAssertEqual(mockDataStore.dict[UserDefaultMigratorConstants.EdgeConsent.DataStoreKeys.CONSENT_PREFERENCES.rawValue] as? [String: String], consentPreferences)
        
        XCTAssertNil(defaults.object(forKey: consentPreferencesKey))
    }
}
