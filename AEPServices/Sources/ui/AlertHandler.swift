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
            if messageMonitor.isDisplayed(){
            Log.debug(label: "\(LOG_TAG):\(#function)", "Failed to show alert, another message is displayed at this time")
            return
            }
            
        }
        
        messageMonitor.displayed()
        
        let alert = AlertViewController(title: title, message: message, preferredStyle: .alert)
        
        if !(positiveButtonText?.isEmpty ?? true) {
            let confirmAction = UIAlertAction(title: positiveButtonText, style: .default) { alertAction in
                alertListener?.onPositiveResponse()
                alertListener?.onDismiss()
                messageMonitor.dismissed()
            }
            alert.addAction(confirmAction)
            
        }
        
        if !(negativeButtonText?.isEmpty ?? true) {
            let cancelAction = UIAlertAction(title: negativeButtonText, style: .default) { alertAction in
                alertListener?.onNegativeReposne()
                alertListener?.onDismiss()
                messageMonitor.dismissed()
            }
            alert.addAction(cancelAction)
        }
        
        let keyWindow = UIApplication.shared.getKeyWindow()
        if let rootViewController = keyWindow?.rootViewController {
            var bestViewController : UIViewController?
            do {
                bestViewController = try findBestViewController(viewController: rootViewController)
            }
            catch {
                // If there is any error in finding the Best view controller log the error and do nothing.
                Log.warning(label: "\(LOG_TAG):\(#function)", "Unable to show Alert. Error in finding best view controller.")
                messageMonitor.dismissed()
            }
            
            if bestViewController?.isViewLoaded ?? false {
                bestViewController!.present(alert, animated: true, completion: nil)
                alertListener?.onShow()
                
            }
        }
        else{
            Log.warning(label: "\(LOG_TAG):\(#function)", "Unable to show Alert. key window is null.")
        }
    }
}

fileprivate extension AlertHandler {
    
    static func findBestViewController(viewController: UIViewController) throws -> UIViewController {
        
        if let presentedViewController = viewController.presentedViewController  {
            // Return presented view controller
            return (try findBestViewController(viewController: presentedViewController));
        } else if let svc = viewController as? UISplitViewController {
            // Return right hand side
            return svc.viewControllers.count > 0 ? try findBestViewController(viewController: svc.viewControllers.last!) : viewController
        } else if let nvc = viewController as? UINavigationController {
            // Return top view
            return nvc.viewControllers.count > 0 ? try findBestViewController(viewController: nvc.topViewController!) : viewController
        } else if let tbc = viewController as? UITabBarController {
            // Return visible view
            return tbc.viewControllers?.count ?? 0 > 0 ? try findBestViewController(viewController: tbc.selectedViewController!) : viewController
        } else if let pvc = viewController as? UIPageViewController {
            // Return visible view
            return pvc.viewControllers?.count ?? 0 > 0 ? try findBestViewController(viewController: pvc.viewControllers![0]) : viewController
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
fileprivate class AlertViewController : UIAlertController {
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        .all
    }
}
