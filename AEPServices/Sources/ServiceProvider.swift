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

///
/// The ServiceProvider Singleton is used to override and provide Core Services
///
public class ServiceProvider {
    public static let shared = ServiceProvider()

    /// MessagingDelegate which is used to listen for message visibility updates.
    public weak var messagingDelegate: MessagingDelegate?

    // Provide thread safety on the getters and setters
    private let queue = DispatchQueue(label: "com.adobe.serviceProvider.queue")

    private var overrideSystemInfoService: SystemInfoService?
    private var defaultSystemInfoService = ApplicationSystemInfoService()
    private var overrideKeyValueService: NamedCollectionProcessing?
    #if os(iOS)
        private var defaultKeyValueService = FileSystemNamedCollection()
    #elseif os(tvOS)
        private var defaultKeyValueService = UserDefaultsNamedCollection()
    #endif
    private var overrideNetworkService: Networking?
    private var defaultNetworkService = NetworkService()
    private var defaultDataQueueService = DataQueueService()
    private var overrideCacheService: Caching?
    private var defaultCacheService = DiskCacheService()
    private var overrideLoggingService: Logging?
    private var defaultLoggingService = LoggingService()

    // Don't allow init of ServiceProvider outside the class
    private init() {}

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

    public var namedKeyValueService: NamedCollectionProcessing {
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

    public var networkService: Networking {
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

    public var dataQueueService: DataQueuing {
        return queue.sync {
            return defaultDataQueueService
        }
    }

    public var cacheService: Caching {
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

    public var loggingService: Logging {
        get {
            return queue.sync {
                return overrideLoggingService ?? defaultLoggingService
            }
        }
        set {
            queue.async {
                self.overrideLoggingService = newValue
            }
        }
    }

    internal func reset() {
        queue.async {
            self.defaultSystemInfoService = ApplicationSystemInfoService()
            #if os(iOS)
                self.defaultKeyValueService = FileSystemNamedCollection()
            #elseif os(tvOS)
                self.defaultKeyValueService = UserDefaultsNamedCollection()
            #endif
            self.defaultNetworkService = NetworkService()
            self.defaultCacheService = DiskCacheService()
            self.defaultDataQueueService = DataQueueService()
            self.defaultLoggingService = LoggingService()

            self.overrideSystemInfoService = nil
            self.overrideKeyValueService = nil
            self.overrideNetworkService = nil
            self.overrideCacheService = nil
            self.overrideLoggingService = nil
        }
    }
}

///
/// ServiceProvider extension for URL services
///
@available(iOSApplicationExtension, unavailable)
@available(tvOSApplicationExtension, unavailable)
extension ServiceProvider {
    private struct URLHolder {
        static var overrideURLService: URLOpening?
        static var defaultURLService = URLService()
    }

    public var urlService: URLOpening {
        get {
            return queue.sync {
                return URLHolder.overrideURLService ?? URLHolder.defaultURLService
            }
        }
        set {
            queue.async {
                URLHolder.overrideURLService = newValue
            }
        }
    }
}

///
/// ServiceProvider extension for UI services (requires iOS/tvOS 13.0 for SwiftUI support)
///
@available(iOSApplicationExtension, unavailable)
@available(tvOSApplicationExtension, unavailable)
@available(iOS 13.0, *)
@available(tvOS 13.0, *)
extension ServiceProvider {
    private struct UIHolder {
        static var overrideUIService: UIService?
        static var defaultUIService = AEPUIService()
    }

    public var uiService: UIService {
        get {
            return queue.sync {
                return UIHolder.overrideUIService ?? UIHolder.defaultUIService
            }
        }
        set {
            queue.async {
                UIHolder.overrideUIService = newValue
            }
        }
    }

    internal func resetAppOnlyServices() {
        queue.async {
            URLHolder.defaultURLService = URLService()
            URLHolder.overrideURLService = nil
            UIHolder.defaultUIService = AEPUIService()
            UIHolder.overrideUIService = nil
        }
    }
}
