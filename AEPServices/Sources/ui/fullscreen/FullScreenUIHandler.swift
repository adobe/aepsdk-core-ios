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

class FullScreenUIHandler: NSObject, WKNavigationDelegate {

    var LOG_TAG = "FullScreenUIHandler"
    private let DOWNLOAD_CACHE = "adbdownloadcache"
    private let HTML_EXTENSION = "html"
    private let TEMP_FILE_NAME = "temp"

    var isLocalImageUsed = false
    var payload: String
    var message: FullScreenMessageUiInterface?
    var listener: FullscreenListenerInterface?
    var monitor: MessageMonitor
    var webView: UIView!

    init(payload: String, message: FullScreenMessageUiInterface, listener: FullscreenListenerInterface, monitor: MessageMonitor, isLocalImageUsed: Bool) {
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

        DispatchQueue.main.async {
            self.monitor.displayed()
            guard var newFrame: CGRect = self.calcFullScreenFrame() else { return }
            newFrame.origin.y = newFrame.size.height
            if newFrame.size.width > 0.0 && newFrame.size.height > 0.0 {
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
                guard var cacheFolder: URL = self.getCacheDirectoryPath() else {
                    return
                }
                cacheFolder.appendPathComponent(self.DOWNLOAD_CACHE)
                let cacheFolderString = cacheFolder.absoluteString
                cacheFolder.appendPathComponent(self.TEMP_FILE_NAME)
                cacheFolder.appendPathComponent(self.HTML_EXTENSION)
                let tempHTMLFilePath = cacheFolder.absoluteString
                if !self.isLocalImageUsed {
                    do {
                        try self.payload.write(toFile: tempHTMLFilePath, atomically: true, encoding: .utf8)
                        useTempHTML = true
                    } catch {
                        // LOG
                    }
                }
                // load the HTML string on WKWebview. If we are using the cached images, then use
                // loadFileURL:allowingReadAccessToURL: to load the html from local file, which will give us the correct
                // permission to read cached files
                if useTempHTML {
                    wkWebView.loadFileURL(URL.init(fileURLWithPath: tempHTMLFilePath), allowingReadAccessTo: URL.init(fileURLWithPath: cacheFolderString))
                } else {
                    wkWebView.loadHTMLString(self.payload, baseURL: Bundle.main.bundleURL)
                }
                let keyWindow = self.getKeyWindow()
                keyWindow?.addSubview(wkWebView)
                UIView.animate(withDuration: 0.3, animations: {
                    var webViewFrame = wkWebView.frame
                    webViewFrame.origin.y = 0
                    wkWebView.frame = webViewFrame
                }, completion: nil)
            }
        }
        self.listener?.onShow(message: self.message)
    }

    func dismiss() {
        DispatchQueue.main.async {
            self.monitor.dismissed()
            self.dismissWithAnimation(animate: true)
            self.listener?.onDismiss(message: self.message)
            self.message = nil
            guard var cacheFolder: URL = self.getCacheDirectoryPath() else {
                return
            }
            cacheFolder.appendPathComponent(self.DOWNLOAD_CACHE)
            cacheFolder.appendPathComponent(self.TEMP_FILE_NAME)
            cacheFolder.appendPathComponent(self.HTML_EXTENSION)
            let tempHTMLFilePath = cacheFolder.absoluteString

            do {
                try FileManager.default.removeItem(atPath: tempHTMLFilePath)
            } catch {
                // LOG
            }
        }
    }

    func openUrl(url: String) {
        if !url.isEmpty {
            guard let urlObj: URL = URL.init(string: url) else {
                return
            }
            UIApplication.shared.open(urlObj, options: [:], completionHandler: nil)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if self.listener != nil {
            guard let shouldOpenUrl = self.listener?.overrideUrlLoad(message: self.message, url: navigationAction.request.url?.absoluteString) else {
                decisionHandler(.allow)
                return
            }
            decisionHandler(shouldOpenUrl ? .allow : .cancel)

        } else {
            decisionHandler(.allow)
        }
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

    // Get user's cache directory path
    func getCacheDirectoryPath() -> URL? {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask)
        if (paths.isEmpty) {
            return nil
        }
        let root = paths[0]
        var dir: ObjCBool = false
        
        if (!FileManager.default.fileExists(atPath: root.path, isDirectory: &dir) && !dir.boolValue) {
            try! FileManager.default.createDirectory(atPath: root.path, withIntermediateDirectories: true, attributes: nil)
        }
        return root
    }

    func dismissWithAnimation(animate: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: animate ? 0.3: 0, animations: {
                guard var newFrame: CGRect = self.calcFullScreenFrame() else {
                    return
                }
                newFrame.origin.y = newFrame.size.height
                self.webView.frame = newFrame
            }) { _ in
                self.webView.removeFromSuperview()
                self.webView = nil
            }
        }
    }
}
