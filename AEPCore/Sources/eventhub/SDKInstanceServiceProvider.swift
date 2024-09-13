/*
 Copyright 2024 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
*/

import AEPServices

/// provides all the services needed by an `Extension` which supports multi-instances.
@objc(AEPSDKInstanceServiceProvider)
public class SDKInstanceServiceProvider: NSObject {

    private let identifier: SDKInstanceIdentifier
    private let logger: Logger

    private var dataStoreInstances: [String: NamedCollectionDataStore] = [:]
    private var dataQueueInstances: [String: DataQueue] = [:]
    private var cacheInstances: [String: Cache] = [:]

    // DispatchQueue to synchronize access to service dictionaries
    private let queue: DispatchQueue

    init(identifier: SDKInstanceIdentifier) {
        self.identifier = identifier
        self.queue = DispatchQueue(label: "com.adobe.sdkInstanceServiceProvider".instanceAwareName(for: identifier))
        self.logger = SDKInstanceLogger(identifier: identifier)
    }

    /// Set the name of the app group that will be used to store the data
    /// - Parameter appGroup: The app group name
    func setAppGroup(_ appGroup: String?) {
        ServiceProvider.shared.namedKeyValueService.setAppGroup(appGroup)
    }

    /// Gets the app group.
    /// - Returns: The app group if set
    func getAppGroup() -> String? {
        return ServiceProvider.shared.namedKeyValueService.getAppGroup()
    }

    /// Attach the instance identifier to the given String `name`.
    /// - Parameter name: the String to attach the instance identifier.
    /// - Returns: the string with the SDK Instance identifier attached.
    func getInstanceAwareName(for name: String) -> String {
        return name.instanceAwareName(for: identifier)
    }

    /// Returns a `NamedCollectionDataStore` with the given `name` appended with this instance's identifier.
    /// - Parameter name: the name of this data store
    /// - Returns: an instance of type `NamedCollectionDataStore` with the given data store `name` appended with the instance identifier.
    public func getNamedCollectionDataStore(name: String) -> NamedCollectionDataStore {
        queue.sync {
            if let dataStore = dataStoreInstances[name] {
                return dataStore
            } else {
                let dataStore = NamedCollectionDataStore(name: name.instanceAwareName(for: identifier))
                dataStoreInstances[name] = dataStore
                return dataStore
            }
        }
    }

    /// Returns a `DataQueue` where the given `label` appended with the instance identifier.
    /// - Parameter label: the  label assigned to the `DataQueue` when created
    /// - Returns: a `DataQueue` with the `label` appended with the instance identifier.
    public func getDataQueue(label: String) -> DataQueue? {
        queue.sync {
            if let dataQueue = dataQueueInstances[label] {
                return dataQueue
            } else {
                let dataQueue = ServiceProvider.shared.dataQueueService.getDataQueue(label: label.instanceAwareName(for: identifier))
                dataQueueInstances[label] = dataQueue
                return dataQueue
            }
        }
    }

    /// Returns a`Cache` with the given cache `name` appended with the instance identifier.
    /// - Parameter name: the name of the cache
    /// - Returns: a `Cache` with the given `name` appended with the instance identifier.
    public func getCache(name: String) -> Cache {
        queue.sync {
            if let cache = cacheInstances[name] {
                return cache
            } else {
                let cache = Cache(name: name.instanceAwareName(for: identifier))
                cacheInstances[name] = cache
                return cache
            }
        }
    }

    /// Returns a `Logger` specific to this SDK instance.
    /// - Returns: a tenant-aware instance of type `Logger`
    public func getLogger() -> Logger {
        return logger
    }

    /// Returns a shared instance of tye `Networking` provided by the shared `ServiceProvider`.
    /// - Returns: a shared instance of type `Networking`
    public func getNetworkService() -> Networking {
        return ServiceProvider.shared.networkService
    }

    /// Returns a shared instance of type `SystemInfoService` provided by the shared `ServiceProvider`.
    /// - Returns: a shared instance of type `SystemInfoService`
    public func getSystemInfoService() -> SystemInfoService {
        return ServiceProvider.shared.systemInfoService
    }

}

@available(iOSApplicationExtension, unavailable)
@available(tvOSApplicationExtension, unavailable)
extension SDKInstanceServiceProvider {

    /// Returns a shared instance of type `URLOpening` provided by the shared `ServiceProvider`.
    /// - Returns: a shared instance of type `URLOpening`
    public func getUrlService() -> URLOpening {
        return ServiceProvider.shared.urlService
    }

    #if os(iOS)
    /// Returns a shared instance of type `UIService` provided by the shared `ServiceProvider`.
    /// - Returns: a shared instance of type `UIService`
    public func getUIService() -> UIService {
        return ServiceProvider.shared.uiService
    }
    #endif
}
