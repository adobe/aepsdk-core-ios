/*
 Copyright 2021 Adobe. All rights reserved.
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

/// This class is used to create and display fullscreen messages on the current view.
@objc(AEPFullscreenMessage)
public class FullscreenMessage: NSObject, WKNavigationDelegate, FullscreenPresentable {

    private let LOG_PREFIX = "FullscreenMessage"
    private let DOWNLOAD_CACHE = "adbdownloadcache"
    private let HTML_EXTENSION = "html"
    private let TEMP_FILE_NAME = "temp"

    let fileManager = FileManager()

    var isLocalImageUsed = false
    var payload: String
    var listener: FullscreenMessageDelegate?
    public private(set) var webView: UIView?
    private var messageMonitor: MessageMonitoring
    private var loadingNavigation: WKNavigation?

    private var messagingDelegate: MessagingDelegate? {
        return ServiceProvider.shared.messagingDelegate
    }

    /// Creates `FullscreenMessage` instance with the payload provided.
    /// WARNING: This API consumes HTML/CSS/JS using an embedded browser control.
    /// This means it is subject to all the risks of rendering untrusted web pages and running untrusted JS.
    /// Treat all calls to this API with caution and make sure input is vetted for safety somewhere.
    ///
    /// - Parameters:
    ///     - payload: String html content to be displayed with the message
    ///     - listener: `FullscreenMessageDelegate` listener to listening the message lifecycle.
    ///     - isLocalImageUsed: If true, an image from the app bundle will be used for the fullscreen message.
    init(payload: String, listener: FullscreenMessageDelegate?, isLocalImageUsed: Bool, messageMonitor: MessageMonitoring) {
        self.payload = payload
        self.listener = listener
        self.isLocalImageUsed = isLocalImageUsed
        self.messageMonitor = messageMonitor
    }

    /// Call this API to hide the fullscreen message.
    /// This API hides the fullscreen message with an animation, but it keeps alive its webView for future reappearances.
    /// Invoking show on a hidden fullscreen message, will display the fullscreen message in the existing state (i.e webView is not re-rendered)
    ///
    /// Important Note : When you are completed using an Fullscreen message. You must call dismiss() to remove it from memory
    public func hide() {
        DispatchQueue.main.async {
            if self.messageMonitor.dismiss() ==  false {
                return
            }
            self.dismissWithAnimation(animate: true, shouldDeallocateWebView: false)
        }
    }

    public func show() {
        if messageMonitor.show(message: self) ==  false {
            self.listener?.onShowFailure()
            return
        }

        // If the webView is already allocated, then reshow them
        if let webView = webView as? WKWebView {
            displayWithAnimation(webView: webView)
            return
        }

        DispatchQueue.main.async {
            guard var newFrame: CGRect = UIUtils.getFrame() else {
                Log.debug(label: self.LOG_PREFIX, "Failed to show the fullscreen message, newly created frame is nil.")
                self.listener?.onShowFailure()
                return
            }
            newFrame.origin.y = newFrame.size.height
            if newFrame.size.width > 0.0 && newFrame.size.height > 0.0 {

                let wkWebView = self.getConfiguredWebView(newFrame: newFrame)

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
                        // We have to use loadFileURL so we can allow read access to these image files in the cache but loadFileURL
                        // expects a file URL and not the string representation of the HTML payload. As a workaround, we can write the
                        // payload string to a temporary HTML file located at cachePath/adbdownloadcache/temp.html and pass that file
                        // URL to loadFileURL.
                        do {
                            try FileManager.default.createDirectory(atPath: cacheFolderURL?.path ?? "", withIntermediateDirectories: true, attributes: nil)
                            try self.payload.write(toFile: tempHTMLFile?.path ?? "", atomically: true, encoding: .utf8)
                            useTempHTML = true
                        } catch {
                            Log.debug(label: self.LOG_PREFIX, "Failed to save the temporary HTML file for fullscreen message \(error)")
                        }
                    }
                }
                // load the HTML string on WKWebView. If we are using the cached images, then use
                // loadFileURL:allowingReadAccessToURL: to load the html from local file, which will give us the correct
                // permission to read cached files
                if useTempHTML {
                    self.loadingNavigation = wkWebView.loadFileURL(URL.init(fileURLWithPath: tempHTMLFile?.path ?? ""), allowingReadAccessTo: URL.init(fileURLWithPath: cacheFolder?.path ?? ""))
                } else {
                    self.loadingNavigation = wkWebView.loadHTMLString(self.payload, baseURL: Bundle.main.bundleURL)
                }

                self.displayWithAnimation(webView: wkWebView)

                // Notifying global listeners
                self.listener?.onShow(message: self)
                self.messagingDelegate?.onShow(message: self)
            }
        }
    }

    public func dismiss() {
        DispatchQueue.main.async {
            if self.messageMonitor.dismiss() ==  false {
                return
            }

            self.dismissWithAnimation(animate: true, shouldDeallocateWebView: true)
            // Notifying all listeners
            self.listener?.onDismiss(message: self)
            self.messagingDelegate?.onDismiss(message: self)

            // remove the temporary html if it exists
            guard var cacheFolder: URL = self.fileManager.getCacheDirectoryPath() else {
                return
            }
            cacheFolder.appendPathComponent(self.DOWNLOAD_CACHE)
            cacheFolder.appendPathComponent(self.TEMP_FILE_NAME)
            cacheFolder.appendPathExtension(self.HTML_EXTENSION)
            let tempHTMLFilePath = cacheFolder.absoluteString

            guard let tempHTMLFilePathUrl = URL(string: tempHTMLFilePath) else {
                Log.debug(label: self.LOG_PREFIX, "Unable to dismiss, error converting temp path \(tempHTMLFilePath) to URL")
                return
            }

            do {
                try FileManager.default.removeItem(at: tempHTMLFilePathUrl)
            } catch {
                Log.debug(label: self.LOG_PREFIX, "Unable to dismiss \(error)")
            }
        }
    }

    // MARK: WKWebView delegate
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if self.listener != nil {
            guard let shouldOpenUrl = self.listener?.overrideUrlLoad(message: self, url: navigationAction.request.url?.absoluteString) else {
                decisionHandler(.allow)
                return
            }
            decisionHandler(shouldOpenUrl ? .allow : .cancel)

        } else {
            // if the API user doesn't provide any listener ( self.listener == nil ),
            // set WKNavigationActionPolicyAllow as a default behavior.
            decisionHandler(.allow)
        }
    }

    /// Delegate method invoked when the webView navigation is complete.
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if navigation == self.loadingNavigation {
            if let funcBlock = self.listener?.webViewDidFinishLoading {
                funcBlock()
            }
        }
    }

    private func getConfiguredWebView(newFrame: CGRect) -> WKWebView {
        let webViewConfiguration = WKWebViewConfiguration()

        // Fix for media playback.
        webViewConfiguration.allowsInlineMediaPlayback = true // Plays Media inline
        webViewConfiguration.mediaTypesRequiringUserActionForPlayback = []
        let wkWebView = WKWebView(frame: newFrame, configuration: webViewConfiguration)
        wkWebView.navigationDelegate = self
        wkWebView.scrollView.bounces = false
        wkWebView.backgroundColor = UIColor.clear
        wkWebView.isOpaque = false
        wkWebView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.webView = wkWebView

        return wkWebView
    }

    private func displayWithAnimation(webView: WKWebView) {
        DispatchQueue.main.async {
            let keyWindow = UIApplication.shared.getKeyWindow()
            keyWindow?.addSubview(webView)
            UIView.animate(withDuration: 0.3, animations: {
                var webViewFrame = webView.frame
                webViewFrame.origin.y = 0
                webView.frame = webViewFrame
            }, completion: nil)
        }
    }

    private func dismissWithAnimation(animate: Bool, shouldDeallocateWebView: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: animate ? 0.3: 0, animations: {
                guard var newFrame: CGRect = UIUtils.getFrame() else {
                    return
                }
                newFrame.origin.y = newFrame.size.height
                self.webView?.frame = newFrame
            }) { _ in
                self.webView?.removeFromSuperview()
                if shouldDeallocateWebView {
                    self.webView = nil
                }
            }
        }
    }
}
