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

import Foundation

public class AEPServiceProvider {
    public static let shared = AEPServiceProvider()
    
    // Provide thread safety on the getters and setters
    private let barrierQueue = DispatchQueue(label: "AEPServiceProvider.barrierQueue")

    private var overrideSystemInfoService: SystemInfoService?
    private var defaultSystemInfoService = ApplicationSystemInfoService()
    private var overrideKeyValueService: NamedKeyValueService?
    private var defaultKeyValueService = NamedUserDefaultKeyValueService()
    private var overrideNetworkService: NetworkService?
    private var defaultNetworkService = AEPNetworkService()
    private var overrideCacheService: CacheService?
    private var defaultCacheService = DiskCacheService()

    /// The SystemInfoService, either set externally (override) or the default implementation
    public var systemInfoService: SystemInfoService {
        get {
            return barrierQueue.sync {
                return overrideSystemInfoService ?? defaultSystemInfoService
            }
        }
        set {
            barrierQueue.async {
                self.overrideSystemInfoService = newValue
            }
        }
    }

    public var namedKeyValueService: NamedKeyValueService {
        get {
            return barrierQueue.sync {
                return overrideKeyValueService ?? defaultKeyValueService
            }
        }
        set {
            barrierQueue.async {
                self.overrideKeyValueService = newValue
            }
        }
    }

    public var networkService: NetworkService {
        get {
            return barrierQueue.sync {
                return overrideNetworkService ?? defaultNetworkService
            }
        }
        set {
            barrierQueue.async {
                self.overrideNetworkService = newValue
            }
        }
    }
    
    public var cacheService: CacheService {
        get {
            return barrierQueue.sync {
                return overrideCacheService ?? defaultCacheService
            }
        }
        set {
            barrierQueue.async {
                self.overrideCacheService = newValue
            }
        }
    }
}
