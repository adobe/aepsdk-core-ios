/*
 Copyright 2022 Adobe. All rights reserved.
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
import AEPServicesMocks


class ServiceProviderTests: XCTestCase {
   
    func testOverridingSystemInfoService() {
        let mockSystemInfoService = MockSystemInfoService()
        ServiceProvider.shared.systemInfoService = mockSystemInfoService
        XCTAssertEqual(Unmanaged.passUnretained(mockSystemInfoService).toOpaque(), Unmanaged.passUnretained(ServiceProvider.shared.systemInfoService as! MockSystemInfoService).toOpaque())
    }
    
    func testResettingSystemInfoService() {
        let mockSystemInfoService = MockSystemInfoService()
        ServiceProvider.shared.systemInfoService = mockSystemInfoService
        ServiceProvider.shared.reset()
        XCTAssertTrue(ServiceProvider.shared.systemInfoService is ApplicationSystemInfoService)
    }
    
    func testOverridingNamedKeyValueService() {
        let mockKeyValueService = MockKeyValueService()
        ServiceProvider.shared.namedKeyValueService = mockKeyValueService
        XCTAssertEqual(Unmanaged.passUnretained(mockKeyValueService).toOpaque(), Unmanaged.passUnretained(ServiceProvider.shared.namedKeyValueService as! MockKeyValueService).toOpaque())
       
    }
    
    func testResettingNamedKeyValueService() {
        let mockNamedKeyValueService = MockKeyValueService()
        ServiceProvider.shared.namedKeyValueService = mockNamedKeyValueService
        ServiceProvider.shared.reset()
        XCTAssertTrue(ServiceProvider.shared.namedKeyValueService is UserDefaultsNamedCollection)
    }
    
    func testOverridingNetworkService() {
        let mockNetworkService = MockNetworkServiceOverrider()
        ServiceProvider.shared.networkService = mockNetworkService
        XCTAssertEqual(Unmanaged.passUnretained(mockNetworkService).toOpaque(), Unmanaged.passUnretained(ServiceProvider.shared.networkService as! MockNetworkServiceOverrider).toOpaque())
    }
    
    func testResettingNetworkService() {
        let mockNetworkService = MockNetworkServiceOverrider()
        ServiceProvider.shared.networkService = mockNetworkService
        ServiceProvider.shared.reset()
        XCTAssertTrue(ServiceProvider.shared.networkService is NetworkService)
    }
    
    func testOverridingCacheService() {
        let mockCacheService = MockDiskCache()
        ServiceProvider.shared.cacheService = mockCacheService
        XCTAssertEqual(Unmanaged.passUnretained(mockCacheService).toOpaque(), Unmanaged.passUnretained(ServiceProvider.shared.cacheService as! MockDiskCache).toOpaque())
    }
    
    func testResettingCacheService() {
        let mockCacheService = MockDiskCache()
        ServiceProvider.shared.cacheService = mockCacheService
        ServiceProvider.shared.reset()
        XCTAssertTrue(ServiceProvider.shared.cacheService is DiskCacheService)
    }
    
    func testOverridingLoggingService() {
        let mockLoggingService = MockLoggingService()
        ServiceProvider.shared.loggingService = mockLoggingService
        XCTAssertEqual(Unmanaged.passUnretained(mockLoggingService).toOpaque(), Unmanaged.passUnretained(ServiceProvider.shared.loggingService as! MockLoggingService).toOpaque())
    }
    
    func testResettingLoggingService() {
        let mockLoggingService = MockLoggingService()
        ServiceProvider.shared.loggingService = mockLoggingService
        ServiceProvider.shared.reset()
        XCTAssertTrue(ServiceProvider.shared.loggingService is LoggingService)
    }
    
    #if os(iOS)
        func testOverridingAppOnlyServices() {
            let mockUIService = MockUIService()
            ServiceProvider.shared.uiService = mockUIService
            XCTAssertEqual(Unmanaged.passUnretained(mockUIService).toOpaque(), Unmanaged.passUnretained(ServiceProvider.shared.uiService as! MockUIService).toOpaque())
        
            let mockURLService = MockURLService()
            ServiceProvider.shared.urlService = mockURLService
            XCTAssertEqual(Unmanaged.passUnretained(mockURLService).toOpaque(), Unmanaged.passUnretained(ServiceProvider.shared.urlService as! MockURLService).toOpaque())
        
        }
        @available(tvOSApplicationExtension, unavailable)
        func testResettingAppOnlyServices() {
            let mockUIService = MockUIService()
            ServiceProvider.shared.uiService = mockUIService
            ServiceProvider.shared.resetAppOnlyServices()
            XCTAssertTrue(ServiceProvider.shared.uiService is AEPUIService)
        
            let mockURLService = MockURLService()
            ServiceProvider.shared.urlService = mockURLService
            ServiceProvider.shared.resetAppOnlyServices()
            XCTAssertTrue(ServiceProvider.shared.urlService is URLService)
        }
    #endif
}
