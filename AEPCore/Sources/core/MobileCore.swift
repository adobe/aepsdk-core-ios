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
@objc(AEPMobileCore) public final class MobileCore: NSObject {
    private static let LOG_TAG = "MobileCore"
    /// Current version of the Core extension
    @objc public static var extensionVersion: String {
        if wrapperType == .none {
            return ConfigurationConstants.EXTENSION_VERSION
        }

        return ConfigurationConstants.EXTENSION_VERSION + "-" + wrapperType.rawValue
    }

    private static var wrapperType = WrapperType.none

    /// Pending extensions to be registered for legacy support
    static var pendingExtensions = ThreadSafeArray<Extension.Type>(identifier: "com.adobe.pendingextensions.queue")

    /// Registers the extensions with Core and begins event processing
    /// - Parameter extensions: The extensions to be registered
    /// - Parameter completion: Closure to run when extensions have been registered
    @objc(registerExtensions:completion:)
    public static func registerExtensions(_ extensions: [Extension.Type], _ completion: (() -> Void)? = nil) {
        let idParser = IDParser()
        V4Migrator(idParser: idParser).migrate() // before starting SDK, migrate from v4 if needed
        V5Migrator(idParser: idParser).migrate() // before starting SDK, migrate from v5 if needed

        let registeredCounter = AtomicCounter()
        let allExtensions = [Configuration.self] + extensions

        allExtensions.forEach {
            EventHub.shared.registerExtension($0) { _ in
                if registeredCounter.incrementAndGet() == allExtensions.count {
                    EventHub.shared.start()
                    completion?()
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

    /// Dispatches an `Event` through the `EventHub`
    /// - Parameter event: The `Event` to be dispatched
    @objc(dispatch:)
    public static func dispatch(event: Event) {
        EventHub.shared.dispatch(event: event)
    }

    /// Dispatches an `Event` through the `EventHub` and invokes a closure with the response `Event`.
    /// - Parameters:
    ///   - event: The trigger `Event` to be dispatched through the `EventHub`
    ///   - responseCallback: Callback to be invoked with `event`'s response `Event`
    @objc(dispatch:responseCallback:)
    public static func dispatch(event: Event, responseCallback: @escaping (Event?) -> Void) {
        EventHub.shared.registerResponseListener(triggerEvent: event, timeout: 1) { event in
            responseCallback(event)
        }

        EventHub.shared.dispatch(event: event)
    }

    /// Submits a generic event containing the provided IDFA with event type `generic.identity`.
    /// - Parameter identifier: the advertising identifier string.
    @objc(setAdvertisingIdentifier:)
    public static func setAdvertisingIdentifier(adId: String?) {
        let data = [CoreConstants.Keys.ADVERTISING_IDENTIFIER: adId ?? ""]
        let event = Event(name: "SetAdvertisingIdentifier", type: EventType.genericIdentity, source: EventSource.requestContent, data: data)
        MobileCore.dispatch(event: event)
    }

    /// Submits a generic event containing the provided push token with event type `generic.identity`.
    /// - Parameter deviceToken: the device token for push notifications
    @objc(setPushIdentifier:)
    public static func setPushIdentifier(deviceToken: Data?) {
        let hexString = SHA256.hexStringFromData(input: deviceToken as NSData?)
        let data = [CoreConstants.Keys.PUSH_IDENTIFIER: hexString]
        let event = Event(name: "SetPushIdentifier", type: EventType.genericIdentity, source: EventSource.requestContent, data: data)
        MobileCore.dispatch(event: event)
    }

    /// Sets the wrapper type for the SDK. Only applicable when being used in a cross platform environment such as React Native
    /// - Parameter type: the `WrapperType` corresponding to the current platform
    @objc(setWrapperType:)
    public static func setWrapperType(type: WrapperType) {
        MobileCore.wrapperType = type
    }

    /// Sets the logging level for the SDK
    /// - Parameter level: The desired log level
    @objc(setLogLevel:)
    public static func setLogLevel(level: LogLevel) {
        Log.logFilter = level
    }

    /// Sets the app group used to sharing user defaults and files among containing app and extension apps.
    /// This must be called in AppDidFinishLaunching and before any other interactions with the Adobe Mobile library have happened.
    /// - Parameter group: the app group name
    @objc(setAppGroup:)
    public static func setAppGroup(group: String?) {
        ServiceProvider.shared.namedKeyValueService.setAppGroup(group)
    }

    /// For scenarios where the app is launched as a result of notification tap
    /// - Parameter messageInfo: Dictionary of data relevant to the expected use case
    @objc(collectMessageInfo:)
    public static func collectMessageInfo(messageInfo: [String: Any]) {
        guard !messageInfo.isEmpty else {
            Log.trace(label: LOG_TAG, "collectMessageInfo - data was empty, no event was dispatched")
            return
        }

        let event = Event(name: "CollectMessageData", type: EventType.genericData, source: EventSource.os, data: messageInfo)
        MobileCore.dispatch(event: event)
    }
}
