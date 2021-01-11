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

public class FullscreenMessage: NSObject, WKNavigationDelegate {
    private let LOG_PREFIX = "FullscreenMessage"
    private let DOWNLOAD_CACHE = "adbdownloadcache"
    private let HTML_EXTENSION = "html"
    private let TEMP_FILE_NAME = "temp"

    let fileManager = FileManager()

    var isLocalImageUsed = false
    var payload: String
    var listener: FullscreenMessaging?
    var webView: UIView!
    
    var messageMonitor: MessageMonitor
    
    /// Creates `FullscreenMessage` instance with the payload provided.
    /// WARNING: This API consumes HTML/CSS/JS using an embedded browser control.
    /// This means it is subject to all the risks of rendering untrusted web pages and running untrusted JS.
    /// Treat all calls to this API with caution and make sure input is vetted for safety somewhere.
    ///
    /// - Parameters:
    ///     - payload: String html content to be displayed with the message
    ///     - listener: `FullscreenMessaging` listener to listening the message lifecycle.
    public convenience init(payload: String, listener: FullscreenMessaging?) {
        self.init(payload: payload, listener: listener, isLocalImageUsed: false)
    }

    /// Creates `FullscreenMessage` instance with the payload provided.
    /// WARNING: This API consumes HTML/CSS/JS using an embedded browser control.
    /// This means it is subject to all the risks of rendering untrusted web pages and running untrusted JS.
    /// Treat all calls to this API with caution and make sure input is vetted for safety somewhere.
    ///
    /// - Parameters:
    ///     - payload: String html content to be displayed with the message
    ///     - listener: `FullscreenMessaging` listener to listening the message lifecycle.
    ///     - isLocalImageUsed: If true, an image from the app bundle will be used for the fullscreen message.
    public init(payload: String, listener: FullscreenMessaging?, isLocalImageUsed: Bool) {
        self.payload = payload
        self.listener = listener
        self.isLocalImageUsed = isLocalImageUsed
        self.messageMonitor = ServiceProvider.shared.messageMonitor
    }

    

    // MARK: WKWebview delegatesou
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if self.listener != nil {
            guard let shouldOpenUrl = self.listener?.overrideUrlLoad(message: self, url: navigationAction.request.url?.absoluteString) else {
                decisionHandler(.allow)
                return
            }
            decisionHandler(shouldOpenUrl ? .allow : .cancel)

        } else {
            // if the API user doesn't provide any listner ( self.listener == nil ),
            // set WKNavigationActionPolicyAllow as a default behaviour.
            decisionHandler(.allow)
        }
    }

    // MARK: web layout helpers
    func calcFullscreenFrame() -> CGRect? {
        var newFrame = CGRect(x: 0, y: 0, width: 0, height: 0)
        // x is always 0
        newFrame.origin.x = 0
        // for fullscreen, width and height are both full screen
        let keyWindow = getKeyWindow()
        guard let screenBounds: CGSize = keyWindow?.frame.size else { return nil }
        newFrame.size = screenBounds

        // y is dependant on visibility and height
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

    func dismissWithAnimation(animate: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: animate ? 0.3: 0, animations: {
                guard var newFrame: CGRect = self.calcFullscreenFrame() else {
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

    /// Open a url from this message
    func openUrl(url: String) {
        guard let urlObj = URL(string: url) else {
            return
        }
        UIApplication.shared.open(urlObj, options: [:], completionHandler: nil)
    }
}

// MARK: - Protocol Methods
extension FullscreenMessage: UIMessaging {

    public func show() {
        if messageMonitor.isMessageDisplayed() {
            Log.debug(label: LOG_PREFIX, "Message couldn't be displayed, another message is displayed at this time.")
            return
        }
        
        if messageMonitor.globalUIMessagingListener?.showMessage() == false {
            Log.debug(label: LOG_PREFIX, "Message couldn't be displayed, globalUIMessaging#showMessage states the message should not be displayed.")
            return
        }
                
        DispatchQueue.main.async {

            guard var newFrame: CGRect = self.calcFullscreenFrame() else { return }
            newFrame.origin.y = newFrame.size.height
            if newFrame.size.width > 0.0 && newFrame.size.height > 0.0 {
                let webViewConfiguration = WKWebViewConfiguration()

                //Fix for media playback.
                webViewConfiguration.allowsInlineMediaPlayback = true // Plays Media inline
                webViewConfiguration.mediaTypesRequiringUserActionForPlayback = []
                let wkWebView = WKWebView(frame: newFrame, configuration: webViewConfiguration)
                self.webView = wkWebView
                wkWebView.navigationDelegate = self
                wkWebView.scrollView.bounces = false
                wkWebView.backgroundColor = UIColor.clear
                wkWebView.isOpaque = false
                wkWebView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

                // Fix for iPhone X to display content edge-to-edge
                if #available(iOS 11, *) {
                    wkWebView.scrollView.contentInsetAdjustmentBehavior = .never
                }

                // save the HTML payload to a local file if the cached image is being used
                var useTempHTML = false
                var cacheFolderURL: URL?
                var tempHTMLFile: URL?
                let cacheFolder: URL? = self.fileManager.getCacheDirectoryPath()
                if cacheFolder != nil {
                    cacheFolderURL = cacheFolder?.appendingPathComponent(self.DOWNLOAD_CACHE)
                    tempHTMLFile = cacheFolderURL?.appendingPathComponent(self.TEMP_FILE_NAME).appendingPathExtension(self.HTML_EXTENSION)
                    if !self.isLocalImageUsed {
                        /* AMSDK-8942: The ACS extension saves downloaded remote image files in the cache. We have to use loadFileURL so we can allow read access to these image files in the cache but loadFileURL expects a file URL and not the string representation of the HTML payload. As a workaround, we can write the payload string to a temporary HTML file located at cachePath/adbdownloadcache/temp.html and pass that file URL to loadFileURL.
                         */
                        do {
                            try FileManager.default.createDirectory(atPath: cacheFolderURL!.path, withIntermediateDirectories: true, attributes: nil)
                            try self.payload.write(toFile: tempHTMLFile!.path, atomically: true, encoding: .utf8)
                            useTempHTML = true
                        } catch {
                            Log.debug(label: self.LOG_PREFIX, "Failed to save the temporary HTML file for fullscreen message \(error)")
                            return
                        }
                    }
                }
                // load the HTML string on WKWebview. If we are using the cached images, then use
                // loadFileURL:allowingReadAccessToURL: to load the html from local file, which will give us the correct
                // permission to read cached files
                if useTempHTML {
                    wkWebView.loadFileURL(URL.init(fileURLWithPath: tempHTMLFile?.path ?? ""), allowingReadAccessTo: URL.init(fileURLWithPath: cacheFolder?.path ?? ""))
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
        self.listener?.onShow(message: self)
    }

    public func remove() {
        DispatchQueue.main.async {
            self.messageMonitor.dismiss()
            
            self.dismissWithAnimation(animate: true)
            self.listener?.onDismiss(message: self)

            // remove the temporary html if it exists
            guard var cacheFolder: URL = self.fileManager.getCacheDirectoryPath() else {
                return
            }
            cacheFolder.appendPathComponent(self.DOWNLOAD_CACHE)
            cacheFolder.appendPathComponent(self.TEMP_FILE_NAME)
            cacheFolder.appendPathComponent(self.HTML_EXTENSION)
            let tempHTMLFilePath = cacheFolder.absoluteString

            do {
                try FileManager.default.removeItem(atPath: tempHTMLFilePath)
            } catch {
                Log.debug(label: self.LOG_PREFIX, "Unable to dismiss \(error)")
            }
        }
    }
}
