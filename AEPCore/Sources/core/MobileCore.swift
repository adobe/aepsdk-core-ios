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

import AEPServices
import Foundation

/// Core extension for the Adobe Experience Platform SDK
@objc(AEPMobileCore)
public final class MobileCore: NSObject {
    private static let LOG_TAG = "MobileCore"

#if DEBUG
    internal static var mobileCoreInitializer = MobileCoreInitializer()
#else
    private static let mobileCoreInitializer = MobileCoreInitializer()
#endif

    /// Current version of the Core extension
    @objc public static var extensionVersion: String {
        let wrapperType = EventHub.shared.getWrapperType()
        if wrapperType == .none {
            return ConfigurationConstants.EXTENSION_VERSION
        }

        return ConfigurationConstants.EXTENSION_VERSION + "-" + wrapperType.rawValue
    }

    @objc public static var messagingDelegate: MessagingDelegate? {
        @available(*, unavailable)
        get { ServiceProvider.shared.messagingDelegate }
        set { ServiceProvider.shared.messagingDelegate = newValue }
    }

    /// Initializes the AEP SDK with the specified `InitOptions`.
    /// This automatically registers all boundled extensions and sets up lifecycle tracking.
    /// You can disable automatic lifecycle tracking using `InitOptions`.
    /// - Parameters:
    ///   - options: The `InitOptions` used to configure the SDK.
    ///   - completion: An optional closure triggered once initialization is complete.
    @available(iOSApplicationExtension, unavailable)
    @available(tvOSApplicationExtension, unavailable)
    @objc(initializeWithOptions:completion:)
    public static func initialize(options: InitOptions, _ completion: (() -> Void)? = nil) {
        mobileCoreInitializer.initialize(options: options, completion)
    }

    /// Initializes the AEP SDK with all bundled extensions, sets up lifecycle tracking,
    /// and configures the SDK using the specified `appId` via `MobileCore.configureWith(appId:)`.
    /// - Parameters:
    ///   - appId: A unique identifier assigned to the app instance by Adobe Tags
    ///   - completion: An optional closure triggered once initialization is complete.
    @available(iOSApplicationExtension, unavailable)
    @available(tvOSApplicationExtension, unavailable)
    @objc(initializeWithAppId:completion:)
    public static func initialize(appId: String, _ completion: (() -> Void)? = nil) {
        mobileCoreInitializer.initialize(appId: appId, completion)
    }

    /// Registers the extensions with Core and begins event processing
    /// - Parameter extensions: The extensions to be registered
    /// - Parameter completion: Closure to run when extensions have been registered
    @objc(registerExtensions:completion:)
    public static func registerExtensions(_ extensions: [NSObject.Type], _ completion: (() -> Void)? = nil) {
        let idParser = IDParser()
        V4Migrator(idParser: idParser).migrate() // before starting SDK, migrate from v4 if needed
        V5Migrator(idParser: idParser).migrate() // before starting SDK, migrate from v5 if needed
        #if os(iOS)
            UserDefaultsMigrator().migrate() // before starting SDK, migrate from UserDefaults if needed
        #endif
        // Invoke registerExtension on legacy extensions
        let legacyExtensions = extensions.filter {!($0.self is Extension.Type)} // All extensions that do not conform to `Extension`
        let registerSelector = Selector(("registerExtension"))

        if NSClassFromString("ACPBridgeExtension") == nil && !legacyExtensions.isEmpty {
            Log.error(label: LOG_TAG, "Attempting to register ACP extensions: \(legacyExtensions), without the compatibility layer present. Can be included via github.com/adobe/aepsdk-compatibility-ios")
        } else {
            for legacyExtension in legacyExtensions {
                if legacyExtension.responds(to: registerSelector) {
                    legacyExtension.perform(registerSelector)
                } else {
                    Log.error(label: LOG_TAG, "Attempting to register non extension type: \(legacyExtension). If this is due to a naming collision, please use full module name when registering. E.g: AEPAnalytics.Analytics.self")
                }
            }
        }

        // Register native extensions
        let registeredCounter = AtomicCounter()
        let allExtensions = [Configuration.self] + extensions
        let nativeExtensions = allExtensions.filter({$0.self is Extension.Type}) as? [Extension.Type] ?? []

        nativeExtensions.forEach {
            EventHub.shared.registerExtension($0) { _ in
                if registeredCounter.incrementAndGet() == nativeExtensions.count {
                    EventHub.shared.start()
                    completion?()
                    return
                }
            }
        }
    }

    /// Registers the extension from MobileCore
    /// - Parameter exten: The extension to be registered
    @objc(registerExtension:completion:)
    public static func registerExtension(_ exten: Extension.Type, _ completion: (() -> Void)? = nil) {
        EventHub.shared.registerExtension(exten) { _ in
            EventHub.shared.shareEventHubSharedState()
            completion?()
        }
    }

    /// Unregisters the extension from MobileCore
    /// - Parameter exten: The extension to be unregistered
    @objc(unregisterExtension:completion:)
    public static func unregisterExtension(_ exten: Extension.Type, _ completion: (() -> Void)? = nil) {
        EventHub.shared.unregisterExtension(exten) { _ in
            completion?()
        }
    }

    /// Fetches a list of registered extensions along with their respective versions
    /// - Returns: list of registered extensions along with their respective versions
    @objc
    public static func getRegisteredExtensions() -> String {
        let registeredExtensions = EventHub.shared.getSharedState(extensionName: EventHubConstants.NAME, event: nil)?.value
        guard let jsonData = try? JSONSerialization.data(withJSONObject: registeredExtensions ?? [:], options: .prettyPrinted) else { return "{}" }
        return String(data: jsonData, encoding: .utf8) ?? "{}"
    }

    /// Dispatches an `Event` through the `EventHub`
    /// - Parameter event: The `Event` to be dispatched
    @objc(dispatch:)
    public static func dispatch(event: Event) {
        EventHub.shared.dispatch(event: event)
    }

    /// Dispatches an `Event` through the `EventHub` and invokes a closure with the response `Event`.
    /// - Parameters:
    ///   - event: The trigger `Event` to be dispatched through the `EventHub`
    ///   - timeout A timeout in seconds, if the response listener is not invoked within the timeout, then the `EventHub` invokes the response listener with a nil `
