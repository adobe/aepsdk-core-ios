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
@objc(AEPExtensionServiceProvider)
public class ExtensionServiceProvider: NSObject {

    private let identifier: SDKInstanceIdentifier
    private let logger: Logger

    init(identifier: SDKInstanceIdentifier, logger: Logger) {
        self.identifier = identifier
        self.logger = logger
    }

    /// Gets the app group.
    /// - Returns: The app group if set
    public func getAppGroup() -> String? {
        return ServiceProvider.shared.namedKeyValueService.getAppGroup()
    }

    /// Append the SDK instance identifer to `label` for use in lables such as in logging or dispatch queues.
    /// If the given identifier is `SDKInstanceIdentifier.default`, then `label` is returned unmodified.
    /// - Parameter name: the String to attach the instance identifier.
    /// - Returns: the string with the SDK Instance identifier attached.
    public func getInstanceAwareLabel(for label: String) -> String {
        return label.instanceAwareLabel(for: identifier)
    }

    /// Adds the SDK instance identifier to `name` for use in filenames.
    /// If the given identifier is `SDKInstanceIdentifier.default`, then `name` is returned unmodifed.
    /// - Parameter name: the String to attach the instance identifier.
    /// - Returns: the string with the SDK Instance identifier attached.
    public func getInstanceAwareFileName(for name: String) -> String {
        return name.instanceAwareFilename(for: identifier)
    }

    /// Returns a `NamedCollectionDataStore` with the SDK instance identifier added to the given `name`.
    /// - Parameter name: the name of this data store
    /// - Returns: a `NamedCollectionDataStore` with the SDK instance identifier added to `name`
    public func getNamedCollectionDataStore(name: String) -> NamedCollectionDataStore {
        NamedCollectionDataStore(name: name.instanceAwareFilename(for: identifier))
    }

    /// Returns a `DataQueue` with the SDK instance identifier added to the given `label`.
    /// - Parameter label: the  label assigned to the `DataQueue` when created
    /// - Returns: a `DataQueue` with the SDK instance identifier added to `label`
    public func getDataQueue(label: String) -> DataQueue? {
        ServiceProvider.shared.dataQueueService.getDataQueue(label: label.instanceAwareFilename(for: identifier))
    }

    /// Returns a`Cache` with the SDK instance identifier added to the given cache `name`.
    /// - Parameter name: the name of the cache
    /// - Returns: a `Cache` with the SDK instance identifier added to `name`
    public func getCache(name: String) -> Cache {
        Cache(name: name.instanceAwareFilename(for: identifier))
    }

    /// Returns a `Logger` specific to this SDK instance.
    /// - Returns: a `Logger` which includes the SDK instance identifier when logging.
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
extension ExtensionServiceProvider {

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
