/*
 Copyright 2025 Adobe. All rights reserved.
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
import UIKit

final class MobileCoreInitializer {

    typealias NotificationObserver = (NSNotification.Name?, Any?, OperationQueue?, @escaping (Notification) -> Void) -> any NSObjectProtocol

    private let LOG_TAG = "MobileCoreInitializer"

    private let UIApplicationSceneManifestKey = "UIApplicationSceneManifest"

    // Flag if 'initialize()' was called
    private let initialized = AtomicCounter()

    // Function to return list of AEP extensions; see `ExtensionFinder`
    private let extensionFinder: () -> [NSObject.Type]

    // Function for bundle information access
    private let bundleInfoProvider: (String) -> Any?

    // Function for adding notification observers
    private let notificationObserver: NotificationObserver

    init(
        extensionFinder: @escaping () -> [NSObject.Type] = ExtensionFinder.getExtensions,
        bundleInfoProvider: @escaping (String) -> Any? = { Bundle.main.object(forInfoDictionaryKey: $0) },
        notificationObserver: @escaping NotificationObserver = NotificationCenter.default.addObserver
    ) {
        self.extensionFinder = extensionFinder
        self.bundleInfoProvider = bundleInfoProvider
        self.notificationObserver = notificationObserver
    }

    @available(iOSApplicationExtension, unavailable)
    @available(tvOSApplicationExtension, unavailable)
    func initialize(options: InitOptions, _ completion: (() -> Void)? = nil) {

        if initialized.incrementAndGet() != 1 {
            Log.debug(label: LOG_TAG, "initialize - ignoring as it was already called.")
            return
        }

        if options.appGroup != nil {
            MobileCore.setAppGroup(options.appGroup)
        }

        if let appId = options.appId {
            MobileCore.configureWith(appId: appId)
        } else if let filePath = options.filePath {
            MobileCore.configureWith(filePath: filePath)
        }

        // Setup Lifecycle tracking if enabled and register extensions.
        // Use background thread to allow caller process to continue during initialization.
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }

            if options.lifecycleAutomaticTrackingEnabled {
                self.setupLifecycle(additionalContextData: options.lifecycleAdditionalContextData)
            } else {
                Log.trace(label: self.LOG_TAG, "initialize - automatic lifecycle tracking disabled.")
            }

            let extensions = self.extensionFinder()
            MobileCore.registerExtensions(extensions) {
                completion?()
            }
        }
    }

    @available(iOSApplicationExtension, unavailable)
    @available(tvOSApplicationExtension, unavailable)
    private func setupLifecycle(additionalContextData: [String: Any]? = nil) {
        // https://developer.apple.com/documentation/BundleResources/Information-Property-List/UIApplicationSceneManifest
        let usingSceneDelegate = bundleInfoProvider(UIApplicationSceneManifestKey) != nil
        Log.trace(label: self.LOG_TAG, "initialize - automatic lifecycle tracking enabled for \(usingSceneDelegate ? "UIScene" : "UIApplication").")

        // Call lifecycleStart immediately
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState != .background {
                MobileCore.lifecycleStart(additionalContextData: additionalContextData)
            }
        }

        if usingSceneDelegate {
            if #available(iOS 13.0, tvOS 13.0, *) {
                _ = notificationObserver(UIScene.willEnterForegroundNotification, nil, nil) { _ in
                    MobileCore.lifecycleStart(additionalContextData: additionalContextData)
                }
                _ = notificationObserver(UIScene.didEnterBackgroundNotification, nil, nil) { _ in
                    MobileCore.lifecyclePause()
                }
            }
        } else {
            _ = notificationObserver(UIApplication.willEnterForegroundNotification, nil, nil) { _ in
                MobileCore.lifecycleStart(additionalContextData: additionalContextData)
            }
            _ = notificationObserver(UIApplication.didEnterBackgroundNotification, nil, nil) { _ in
                MobileCore.lifecyclePause()
            }
        }
    }
}
