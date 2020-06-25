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
    private let queue = DispatchQueue(label: "AEPServiceProvider.barrierQueue")

    private var overrideSystemInfoService: SystemInfoService?
    private var defaultSystemInfoService = ApplicationSystemInfoService()
    private var overrideKeyValueService: NamedKeyValueService?
    private var defaultKeyValueService = NamedUserDefaultKeyValueService()
    private var overrideNetworkService: NetworkService?
    private var defaultNetworkService = AEPNetworkService()
    private var defaultDataQueueService = AEPDataQueueService.shared
    private var overrideCacheService: CacheService?
    private var defaultCacheService = DiskCacheService()

    /// The SystemInfoService, either set externally (override) or the default implementation
    public var systemInfoService: SystemInfoService {
        get {
            return queue.sync {
                return overrideSystemInfoService ?? defaultSystemInfoService
            }
        }
        set {
            queue.async {
                self.overrideSystemInfoService = newValue
            }
        }
    }

    public var namedKeyValueService: NamedKeyValueService {
        get {
            return queue.sync {
                return overrideKeyValueService ?? defaultKeyValueService
            }
        }
        set {
            queue.async {
                self.overrideKeyValueService = newValue
            }
        }
    }

    public var networkService: NetworkService {
        get {
            return queue.sync {
                return overrideNetworkService ?? defaultNetworkService
            }
        }
        set {
            queue.async {
                self.overrideNetworkService = newValue
            }
        }
    }

    public var dataQueueService: DataQueueService {
        return queue.sync {
            return defaultDataQueueService
        }
    }

    public var cacheService: CacheService {
        get {
            return queue.sync {
                return overrideCacheService ?? defaultCacheService
            }
        }
        set {
            queue.async {
                self.overrideCacheService = newValue
            }
        }
    }
}
