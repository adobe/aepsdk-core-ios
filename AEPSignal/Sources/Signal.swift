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

import AEPCore
import AEPServices
import Foundation

@objc(AEPMobileSignal)
@available(iOSApplicationExtension, unavailable)
@available(tvOSApplicationExtension, unavailable)
public class Signal: NSObject, Extension {

    private(set) var hitQueue: HitQueuing

    // MARK: - Extension

    public let runtime: ExtensionRuntime

    public let name = SignalConstants.EXTENSION_NAME
    public let friendlyName = SignalConstants.FRIENDLY_NAME
    public static let extensionVersion = SignalConstants.EXTENSION_VERSION
    public let metadata: [String: String]? = nil

    public required init?(runtime: ExtensionRuntime) {
        guard let dataQueue = ServiceProvider.shared.dataQueueService.getDataQueue(label: name) else {
            Log.error(label: SignalConstants.LOG_PREFIX, "Signal extension could not be initialized - unable to create a DataQueue.")
            return nil
        }

        hitQueue = PersistentHitQueue(dataQueue: dataQueue, processor: SignalHitProcessor())
        self.runtime = runtime

        super.init()
    }

    // internal init added for testing
    internal init(runtime: ExtensionRuntime, hitQueue: HitQueuing) {
        self.hitQueue = hitQueue
        self.runtime = runtime
        super.init()
    }

    public func onRegistered() {
        registerListener(type: EventType.configuration, source: EventSource.responseContent, listener: handleConfigurationResponse)
        registerListener(type: EventType.rulesEngine, source: EventSource.responseContent, listener: handleRulesEngineResponse)
    }

    public func onUnregistered() {
        hitQueue.close()
    }

    public func readyForEvent(_ event: Event) -> Bool {
        return getSharedState(extensionName: SignalConstants.Configuration.NAME, event: event)?.status == .set
    }

    // MARK: - Event Listeners

    /// Handles the configuration response event
    /// - Parameter event: the configuration response event
    private func handleConfigurationResponse(event: Event) {
        if let privacyStatusStr = event.data?[SignalConstants.Configuration.GLOBAL_PRIVACY] as? String {
            let privacyStatus = PrivacyStatus(rawValue: privacyStatusStr) ?? PrivacyStatus.unknown
            hitQueue.handlePrivacyChange(status: privacyStatus)
            if privacyStatus == .optedOut {
                Log.debug(label: SignalConstants.LOG_PREFIX, "Device has opted-out of tracking. Clearing the Signal queue.")
            }
        }
    }

    private func handleRulesEngineResponse(event: Event) {
        if shouldIgnore(event: event) {
            return
        }

        if event.isPostback || event.isCollectPii {
            handlePostback(event: event)
        } else if event.isOpenUrl {
            handleOpenURL(event: event)
        }
    }

    // MARK: - Rule Consequence Handling

    /// Handles a postback in the form of a GET or POST HTTPS request
    ///
    /// This method is used to handle both "Postback" and "Collect PII" rule consequences.
    /// In either case, the full definition of the request to be sent is contained in the
    /// payload of the event parameter.
    ///
    /// - Parameter event: the event containing postback definition
    private func handlePostback(event: Event) {
        guard let urlString = event.templateUrl else {
            Log.warning(label: SignalConstants.LOG_PREFIX, "Dropping postback, missing templateurl from EventData.")
            return
        }

        // https required for pii calls
        if event.isCollectPii && !urlString.starts(with: "https") {
            Log.warning(label: SignalConstants.LOG_PREFIX, "Dropping collect pii call, url must be https.")
            return
        }

        guard let url = URL(string: urlString) else {
            Log.warning(label: SignalConstants.LOG_PREFIX, "Dropping postback, templateurl from EventData is malformed.")
            return
        }

        guard let postbackJsonData = try? JSONEncoder().encode(SignalHit(url: url, postBody: event.templateBody, contentType: event.contentType ?? SignalConstants.Defaults.CONTENT_TYPE, timeout: event.timeout, event: event)) else {
            Log.debug(label: SignalConstants.LOG_PREFIX, "Dropping postback, unable to encode JSON data.")
            return
        }

        hitQueue.queue(entity: DataEntity(data: postbackJsonData))
    }

    private func handleOpenURL(event: Event) {
        guard let urlString = event.urlToOpen else {
            Log.warning(label: SignalConstants.LOG_PREFIX, "Unable to process OpenURL consequence - no URL was found in EventData.")
            return
        }

        guard let url = URL(string: urlString) else {
            Log.warning(label: SignalConstants.LOG_PREFIX, "Unable to process OpenURL consequence - URL in EventData was malformed.")
            return
        }

        Log.debug(label: SignalConstants.LOG_PREFIX, "Opening URL \(url.absoluteString)")
        ServiceProvider.shared.urlService.openUrl(url)
    }

    // MARK: - Helpers

    /// Determines if the event should be ignored by the Signal extension
    ///
    /// This method will only be called after an Event has been passed to the Signal extension. The requirements for
    /// processing an event at that point should only ever be that a Configuration exists, and that the user has not
    /// opted out of tracking
    ///
    /// - Parameter event: the event in question
    /// - Returns: true if the event should be ignored
    private func shouldIgnore(event: Event) -> Bool {
        guard let configSharedState = getSharedState(extensionName: SignalConstants.Configuration.NAME, event: event)?.value else {
            Log.debug(label: SignalConstants.LOG_PREFIX, "Configuration is unavailable - unable to process event '\(event.id)'.")
            return true
        }

        let privacyStatusStr = configSharedState[SignalConstants.Configuration.GLOBAL_PRIVACY] as? String ?? ""
        let privacyStatus = PrivacyStatus(rawValue: privacyStatusStr) ?? PrivacyStatus.unknown

        return privacyStatus == .optedOut
    }
}
