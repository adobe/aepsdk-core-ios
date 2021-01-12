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
import UIKit
import WebKit

public class AlertMessage: NSObject {
    private let LOG_PREFIX = "AlertMessage"
        
    private let title: String
    private let message: String
    private let positiveButtonLabel: String?
    private let negativeButtonLabel: String?
    private var listener: AlertMessaging?
    
    init(title: String, message: String, positiveButtonLabel: String?, negativeButtonLabel: String?, listener: AlertMessaging?) {
        self.title = title
        self.message = message
        self.positiveButtonLabel = positiveButtonLabel
        self.negativeButtonLabel = negativeButtonLabel
        self.listener = listener
    }
    
    public func show() {
        if ServiceProvider.shared.messageMonitor.show() == false {
            return
        }
        
        DispatchQueue.main.async {
            let alert = UIAlertController.init(title: self.title, message: self.message, preferredStyle: .alert)
            
            if let positiveButton = self.positiveButtonLabel, !positiveButton.isEmpty {
                alert.addAction(UIAlertAction.init(title: positiveButton, style: .default, handler: { (UIAlertAction) in
                    self.listener?.OnPositiveResponse()
                    self.dismiss()
                }))
            }
            if let negativeButton = self.negativeButtonLabel, !negativeButton.isEmpty  {
                alert.addAction(UIAlertAction.init(title: negativeButton, style: .cancel, handler: { (UIAlertAction) in
                    self.listener?.OnNegativeResponse()
                    self.dismiss()
                }))
            }

            let keyWindow = UIApplication.shared.getKeyWindow()
            if let rootViewController = keyWindow?.rootViewController {
                let bestViewController = self.findBestViewController(viewController: rootViewController)

                if bestViewController.isViewLoaded {
                    bestViewController.present(alert, animated: true) {
                        self.listener?.onShow()
                    }
                }
                else {
                    Log.warning(label: "\(self.LOG_PREFIX):\(#function)", "Unable to show Alert. ViewController is not loaded.")
                    ServiceProvider.shared.messageMonitor.dismissMessage()
                }
            }
            else{
                Log.warning(label: "\(self.LOG_PREFIX):\(#function)", "Unable to show Alert. KeyWindow is null.")
                ServiceProvider.shared.messageMonitor.dismissMessage()
            }
        }
    }
    
    /// Returns the topmost view controlller that will be used to present Alert View Controller.
    /// - Parameter viewController: The root view controller of Window.
    /// - Throws: throws any Error that occurs while iterating view hierarchy.
    /// - Returns: returns the best view controller that will be used for presenting Alert View Controller.
    private func findBestViewController(viewController: UIViewController) -> UIViewController {
        if let presentedViewController = viewController.presentedViewController {
            // Return presented view controller
            return findBestViewController(viewController: presentedViewController)
        } else if viewController.isKind(of: UISplitViewController.self), let svc = viewController as? UISplitViewController {
            // Return right hand side
            if !svc.viewControllers.isEmpty, let lastViewController = svc.viewControllers.last {
                return findBestViewController(viewController: lastViewController)
            } else{
                return viewController
            }

        } else if viewController.isKind(of: UINavigationController.self), let nvc = viewController as? UINavigationController {
            // Return top view
            if !nvc.viewControllers.isEmpty, let topViewController = nvc.topViewController {
                return findBestViewController(viewController: topViewController)
            } else{
                return viewController
            }

        } else if viewController.isKind(of: UITabBarController.self), let tbc = viewController as? UITabBarController {
            // Return visible view
            if let selectedViewController = tbc.selectedViewController {
                return findBestViewController(viewController: selectedViewController)
            } else{
                return viewController
            }
        } else if viewController.isKind(of: UIPageViewController.self), let pvc = viewController as? UIPageViewController {
            // Return visible view
            if let pageViewController = pvc.viewControllers?[0] {
                return findBestViewController(viewController: pageViewController)
            } else{
                return viewController
            }
        } else {
            // Unknown view controller type, return last child view controller
            return viewController
        }
    }
    
    private func dismiss() {
        if ServiceProvider.shared.messageMonitor.dismiss() == false {
            return
        }
        self.listener?.onDismiss()
    }
}
