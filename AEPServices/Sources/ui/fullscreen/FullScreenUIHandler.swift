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

func ADBOrientationIsPortrait() -> Bool {
    UIApplication.shared.statusBarOrientation.isPortrait
}

class FullScreenUIHandler : NSObject, WKNavigationDelegate {
    
    var LOG_TAG = "FullScreenUIHandler"
    private let DOWNLOAD_CACHE = "adbdownloadcache"
    private let HTML_EXTENSION = "html"
    private let TEMP_FILE_NAME = "temp"
    
    var isLocalImageUsed = false
    var payload: String?
    var message: FullScreenMessageUiInterface?
    var listener: FullscreenListenerInterface?
    var monitor: MessageMonitor
    var webView: UIView
    
    init(payload: String, message: FullScreenMessageUiInterface, listener : FullscreenListenerInterface, monitor: MessageMonitor, isLocalImageUsed: Bool) {
        self.payload = payload
        self.message = message
        self.listener = listener
        self.monitor = monitor
        self.isLocalImageUsed = isLocalImageUsed
    }
    
    func show() {
        if monitor.isDisplayed() {
            return
        }

        monitor.displayed()
        DispatchQueue.main.async {
            guard var newFrame: CGRect = self.calcFullScreenFrame() else { return }
            newFrame.origin.y = newFrame.size.height
            do {
                if (newFrame.size.width > 0.0 && newFrame.size.height > 0.0) {
                    let webViewConfiguration = WKWebViewConfiguration()
                    webViewConfiguration.allowsInlineMediaPlayback = true
                    webViewConfiguration.mediaTypesRequiringUserActionForPlayback = []
                    let wkWebView = WKWebView(frame: newFrame, configuration: webViewConfiguration)
                    self.webView = wkWebView
                    wkWebView.navigationDelegate = self
                    wkWebView.scrollView.bounces = false
                    wkWebView.backgroundColor = UIColor.clear
                    wkWebView.isOpaque = false
                    wkWebView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    if #available(iOS 11, *) {
                        wkWebView.scrollView.contentInsetAdjustmentBehavior = .never
                    }
                    var useTempHTML = false
                }
            } catch {
                
            }
        }
    }
    
    func dismiss() {
        
    }
    
    func openUrl(url: String) {
        
    }
    
    func calcFullScreenFrame() -> CGRect? {
        var newFrame = CGRect(x: 0, y: 0, width: 0, height: 0)
        // x is always 0
        newFrame.origin.x = 0
        // for fullscreen, width and height are both full screen
        let keyWindow = getKeyWindow()
        guard let screenBounds: CGSize = keyWindow?.frame.size else { return nil }
        newFrame.size = screenBounds
        
        newFrame.origin.y = 0
        return newFrame
    }
    
    func getKeyWindow() -> UIWindow? {
        var keyWindow = UIApplication.shared.keyWindow

        if keyWindow == nil {
            keyWindow = UIApplication.shared.windows.first
        }

        return keyWindow
    }
}
