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
    private let LOG_TAG = "MobileCoreInitializer"

    // Flag if 'initialize()' was called
    private let initialized = AtomicCounter()

#if DEBUG
    // Function to return list of classes; (Protocol) -> [AnyClass]
    public internal(set) var classFinder = ClassFinder.classes(conformToProtocol:)
#else
    // Function to return list of classes; (Protocol) -> [AnyClass]
    private let classFinder = ClassFinder.classes(conformToProtocol:)
#endif

#if DEBUG
    public internal(set) static var shared = MobileCoreInitializer()
#else
    static let shared = MobileCoreInitializer()
#endif

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
        // ClassFinder Extension discover requires a small but non-negligible amount of time to run, so
        // use background thread to allow caller process to continue during initialization.
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }

            if options.lifecycleAutomaticTrackingEnabled == true {
                self.setupLifecycle(additionalContextData: options.lifecycleAdditionalContextData)
            } else {
                Log.trace(label: self.LOG_TAG, "initialize - automatic lifecycle tracking disabled.")
            }

            let classList = self.classFinder(Extension.self)
            // EventHub automatically registers Configuration and the Placeholder extensions, filter them out from list to prevent duplicate registration warnings.
            let filteredClassList = classList.filter { $0 !== AEPCore.EventHubPlaceholderExtension.self && $0 !== AEPCore.Configuration.self }.compactMap { $0 as? NSObject.Type }
            MobileCore.registerExtensions(filteredClassList) {
                completion?()
            }
        }
    }

    @available(iOSApplicationExtension, unavailable)
    @available(tvOSApplicationExtension, unavailable)
    private func setupLifecycle(additionalContextData: [String: Any]? = nil) {
        var usingSceneDelegate = false
        if #available(iOS 13.0, tvOS 13.0, *) {
            let sceneDelegateClasses = self.classFinder(UIWindowSceneDelegate.self)
            if !sceneDelegateClasses.isEmpty {
                usingSceneDelegate = true
            }
        }

        Log.trace(label: self.LOG_TAG, "initialize - automatic lifecycle tracking enabled for \(usingSceneDelegate ? "UIScene" : "UIApplication").")

        // Call lifecycleStart immediately
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState != .background {
                MobileCore.lifecycleStart(additionalContextData: additionalContextData)
            }
        }

        if usingSceneDelegate {
            if #available(iOS 13.0, tvOS 13.0, *) {
                NotificationCenter.default.addObserver(forName: UIScene.willEnterForegroundNotification, object: nil, queue: nil) { _ in
                    MobileCore.lifecycleStart(additionalContextData: additionalContextData)
                }
                NotificationCenter.default.addObserver(forName: UIScene.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
                    MobileCore.lifecyclePause()
                }
            }
        } else {
            NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { _ in
                MobileCore.lifecycleStart(additionalContextData: additionalContextData)
            }
            NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
                MobileCore.lifecyclePause()
            }
        }
    }
}
