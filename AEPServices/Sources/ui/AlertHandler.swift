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

import UIKit


// Class resposible of displaying Alert dialog.
class AlertHandler {
    
    private static let LOG_TAG = "AlertHandler"
    
    private init(){}
    
    static func showAlert(withTitle title: String, message: String, positiveButtonText: String?, negativeButtonText: String?, alertListener: UIAlertListener?, messageMonitor: MessageMonitor){
        
        guard !title.isEmpty && !message.isEmpty else {
            Log.debug(label: "\(LOG_TAG):\(#function)", "Unable to show Alert. Required field Title or message is empty.")
            return
        }
        
        DispatchQueue.main.async {
            // Check if the alert is already on screen then return.
            if messageMonitor.isDisplayed() {
                Log.debug(label: "\(LOG_TAG):\(#function)", "Failed to show alert, another message is displayed at this time")
                return
            }
            
            messageMonitor.displayed()
            
            let alert = AlertViewController(title: title, message: message, preferredStyle: .alert)
            
            if let positiveButton = positiveButtonText, !positiveButton.isEmpty {
                let confirmAction = UIAlertAction(title: positiveButton, style: .default) { alertAction in
                    alertListener?.onPositiveResponse()
                    alertListener?.onDismiss()
                    messageMonitor.dismissed()
                }
                alert.addAction(confirmAction)
            }
            
            if let negativeButton = negativeButtonText, !negativeButton.isEmpty {
                let cancelAction = UIAlertAction(title: negativeButton, style: .default) { alertAction in
                    alertListener?.onNegativeReposne()
                    alertListener?.onDismiss()
                    messageMonitor.dismissed()
                }
                alert.addAction(cancelAction)
            }
            
            let keyWindow = UIApplication.shared.getKeyWindow()
            if let rootViewController = keyWindow?.rootViewController {
                let bestViewController = findBestViewController(viewController: rootViewController)
                
                if bestViewController.isViewLoaded {
                    bestViewController.present(alert, animated: true) {
                        alertListener?.onShow()
                    }
                }
                else {
                    Log.warning(label: "\(LOG_TAG):\(#function)", "Unable to show Alert. ViewController is not loaded.")
                    messageMonitor.dismissed()
                }
            }
            else{
                Log.warning(label: "\(LOG_TAG):\(#function)", "Unable to show Alert. KeyWindow is null.")
                messageMonitor.dismissed()
            }
        }
    }
}

private extension AlertHandler {
    
    /// Returns the topmost view controlller that will be used to present Alert View Controller.
    /// - Parameter viewController: The root view controller of Window.
    /// - Throws: throws any Error that occurs while iterating view hierarchy.
    /// - Returns: returns the best view controller that will be used for presenting Alert View Controller.
    static func findBestViewController(viewController: UIViewController) -> UIViewController {
        
        if let presentedViewController = viewController.presentedViewController {
            // Return presented view controller
            return findBestViewController(viewController: presentedViewController)
        } else if viewController.isKind(of: UISplitViewController.self), let svc = viewController as? UISplitViewController {
            // Return right hand side
            if svc.viewControllers.count > 0, let lastViewController = svc.viewControllers.last{
                return findBestViewController(viewController: lastViewController)
            }
            else{
                return viewController
            }
            
        } else if viewController.isKind(of: UINavigationController.self), let nvc = viewController as? UINavigationController{
            // Return top view
            if nvc.viewControllers.count > 0, let topViewController = nvc.topViewController {
                return findBestViewController(viewController: topViewController)
            }
            else{
                return viewController
            }
            
        } else if viewController.isKind(of: UITabBarController.self), let tbc = viewController as? UITabBarController {
            // Return visible view
            if let selectedViewController = tbc.selectedViewController {
                return findBestViewController(viewController: selectedViewController)
            }
            else{
                return viewController
            }
        } else if viewController.isKind(of: UIPageViewController.self), let pvc = viewController as? UIPageViewController {
            // Return visible view
            if let pageViewController = pvc.viewControllers?[0]{
                return findBestViewController(viewController: pageViewController)
            }
            else{
                return viewController
            }
        } else {
            // Unknown view controller type, return last child view controller
            return viewController
        }
    }
}

extension UIApplication {
    
    func getKeyWindow() -> UIWindow? {
        keyWindow ?? windows.first
    }
}

// AMSDK-2101 - workaround apple alert crash
private class AlertViewController : UIAlertController {
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        .all
    }
}
