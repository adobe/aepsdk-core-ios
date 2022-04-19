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
@available(iOSApplicationExtension, unavailable)
public class FullscreenMessage: NSObject, FullscreenPresentable {

    let LOG_PREFIX = "FullscreenMessage"
    private let DOWNLOAD_CACHE = "adbdownloadcache"
    private let HTML_EXTENSION = "html"
    private let TEMP_FILE_NAME = "temp"
    private let ANIMATION_DURATION = 0.3

    /// Assignable in the constructor, `settings` control the layout and behavior of the message
    @objc
    public var settings: MessageSettings?

    /// Native functions that can be called from javascript
    /// See `addHandler:forScriptMessage:`
    var scriptHandlers: [String: (Any?) -> Void] = [:]

    let fileManager = FileManager()

    var isLocalImageUsed = false
    var payload: String
    weak var listener: FullscreenMessageDelegate?
    public internal(set) var webView: UIView?
    private(set) var transparentBackgroundView: UIView?
    private(set) var messageMonitor: MessageMonitoring

    var loadingNavigation: WKNavigation?
    var messagingDelegate: MessagingDelegate? {
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
    ///     - settings: The `MessageSettings` object defining layout and behavior of the new message
    init(payload: String, listener: FullscreenMessageDelegate?, isLocalImageUsed: Bool, messageMonitor: MessageMonitoring, settings: MessageSettings? = nil) {
        self.payload = payload
        self.listener = listener
        self.isLocalImageUsed = isLocalImageUsed
        self.messageMonitor = messageMonitor
        self.settings = settings
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
            self.dismissWithAnimation(shouldDeallocateWebView: false)
        }
    }

    /// Attempt to create and show the in-app message.
    ///
    /// Order of operations:
    /// 1. check if the webview has already been created
    ///     a. if yes, check if the messageMonitor is allowing the message to be shown
    ///         i. if yes, show the message and exit the function
    ///         ii. if no, call onShowFailure of the listener and exit the function
    ///     b. if no, create the webview and assign delegates
    /// 2. check if the messageMonitor is allowing the message to be shown
    ///     a. if yes, show the message and exit the function
    ///     b. if no, call onShowFailure of the listener and exit the function
    public func show() {
        DispatchQueue.main.async {
            // check if the webview has already been created
            if let webview = self.webView as? WKWebView {
                // it has, determine if the monitor wants to show the message
                guard self.messageMonitor.show(message: self) else {
                    self.listener?.onShowFailure()
                    return
                }

                // notify global listeners
                self.listener?.onShow(message: self)
                self.messagingDelegate?.onShow(message: self)

                self.displayWithAnimation(webView: webview)
                return
            }

            // create the webview
            let wkWebView = self.getConfiguredWebView(newFrame: self.frameBeforeShow)

            // save the HTML payload to a local file if the cached image is being used
            var useTempHTML = false
            var cacheFolderURL: URL?
            var tempHTMLFile: URL?
            let cacheFolder: URL? = self.fileManager.getCacheDirectoryPath()
            if cacheFolder != nil {
                cacheFolderURL = cacheFolder?.appendingPathComponent(self.DOWNLOAD_CACHE)
                tempHTMLFile = cacheFolderURL?.appendingPathComponent(self.TEMP_FILE_NAME).appendingPathExtension(self.HTML_EXTENSION)
                if self.isLocalImageUsed, let file = tempHTMLFile {
                    // We have to use loadFileURL so we can allow read access to these image files in the cache but loadFileURL
                    // expects a file URL and not the string representation of the HTML payload. As a workaround, we can write the
                    // payload string to a temporary HTML file located at cachePath/adbdownloadcache/temp.html and pass that file
                    // URL to loadFileURL.
                    do {
                        try FileManager.default.createDirectory(atPath: cacheFolderURL?.path ?? "", withIntermediateDirectories: true, attributes: nil)
                        let tempHtml = self.payload.data(using: .utf8, allowLossyConversion: false)
                        try tempHtml?.write(to: file, options: .noFileProtection)
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

            // only show the message if the monitor allows it
            guard self.messageMonitor.show(message: self) else {
                self.listener?.onShowFailure()
                return
            }

            // notify global listeners
            self.listener?.onShow(message: self)
            self.messagingDelegate?.onShow(message: self)

            self.displayWithAnimation(webView: wkWebView)
        }
    }

    public func dismiss() {
        DispatchQueue.main.async {
            if self.messageMonitor.dismiss() ==  false {
                return
            }

            self.dismissWithAnimation(shouldDeallocateWebView: true)
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

    /// Adds an entry to `scriptHandlers` for the provided message name.
    /// Handlers can be invoked from javascript in the message via
    /// - Parameters:
    ///   - name: the name of the message being passed from javascript
    ///   - handler: a method to be called when the javascript message is passed
    public func handleJavascriptMessage(_ name: String, withHandler handler: @escaping (Any?) -> Void) {
        DispatchQueue.main.async {
            // don't add the handler if it's already been added
            guard self.scriptHandlers[name] == nil else {
                return
            }

            // if the webview has already been created, we need to add the script handler to existing content controller
            if let webView = self.webView as? WKWebView {
                webView.configuration.userContentController.add(self, name: name)
            }

            self.scriptHandlers[name] = handler
        }
    }

    // MARK: - private methods

    private func getConfiguredWebView(newFrame: CGRect) -> WKWebView {
        let webViewConfiguration = WKWebViewConfiguration()

        // load javascript handlers
        let contentController = WKUserContentController()
        scriptHandlers.forEach {
            contentController.add(self, name: $0.key)
        }
        webViewConfiguration.userContentController = contentController

        // Fix for media playback.
        webViewConfiguration.allowsInlineMediaPlayback = true // Plays Media inline
        webViewConfiguration.mediaTypesRequiringUserActionForPlayback = []
        let wkWebView = WKWebView(frame: newFrame, configuration: webViewConfiguration)
        wkWebView.navigationDelegate = self
        wkWebView.scrollView.bounces = false
        wkWebView.scrollView.layer.cornerRadius = settings?.cornerRadius ?? 0.0
        wkWebView.backgroundColor = UIColor.clear
        wkWebView.isOpaque = false
        wkWebView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Fix for iPhone X to display content edge-to-edge
        if #available(iOS 11, *) {
            wkWebView.scrollView.contentInsetAdjustmentBehavior = .never
        }

        // if this is a ui takeover, add an invisible view over under the webview
        if let takeover = settings?.uiTakeover, takeover {
            transparentBackgroundView = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
            transparentBackgroundView?.backgroundColor = settings?.getBackgroundColor()
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            transparentBackgroundView?.addGestureRecognizer(tap)
        }

        // add gesture recognizers
        if let gestures = settings?.gestures {
            // if gestures are supported, we need to disable scrolling in the webview
            wkWebView.scrollView.isScrollEnabled = false
            // loop through and add gesture recognizers
            for gesture in gestures {
                let gestureRecognizer = MessageGestureRecognizer(gesture: gesture.key, dismissAnimation: settings?.dismissAnimation, url: gesture.value, target: self, action: #selector(handleGesture(_:)))
                if let direction = gestureRecognizer.swipeDirection {
                    gestureRecognizer.direction = direction
                }
                wkWebView.addGestureRecognizer(gestureRecognizer)
            }
        }

        self.webView = wkWebView

        return wkWebView
    }

    @objc func handleGesture(_ sender: UIGestureRecognizer? = nil) {
        DispatchQueue.main.async {
            guard let recognizer = sender as? MessageGestureRecognizer else {
                Log.trace(label: self.LOG_PREFIX, "Unable to handle message gesture - failed to convert UIGestureRecognizer to MessageGestureRecognizer.")
                return
            }

            if let url = recognizer.actionUrl, let wkWebView = self.webView as? WKWebView {
                wkWebView.evaluateJavaScript("window.location = '\(url.absoluteString)'")
            }
        }
    }

    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        dismiss()
    }

    private func displayWithAnimation(webView: WKWebView) {
        DispatchQueue.main.async {
            let keyWindow = UIApplication.shared.getKeyWindow()

            if let animation = self.settings?.displayAnimation, animation != .none {
                let isFade = animation == .fade
                webView.alpha = isFade ? 0.0 : 1.0
                if let bgView = self.transparentBackgroundView {
                    bgView.addSubview(webView)
                    bgView.backgroundColor = self.settings?.getBackgroundColor(opacity: 0.0)
                    keyWindow?.addSubview(bgView)
                } else {
                    keyWindow?.addSubview(webView)
                }
                UIView.animate(withDuration: self.ANIMATION_DURATION, animations: {
                    webView.frame = self.frameWhenVisible
                    webView.alpha = 1.0
                    self.transparentBackgroundView?.backgroundColor = self.settings?.getBackgroundColor()
                })
            } else {
                webView.frame = self.frameWhenVisible
                keyWindow?.addSubview(webView)
            }
        }
    }

    private func dismissWithAnimation(shouldDeallocateWebView: Bool) {
        DispatchQueue.main.async {
            if let animation = self.settings?.dismissAnimation, animation != .none {
                UIView.animate(withDuration: self.ANIMATION_DURATION, animations: {
                    self.webView?.frame = self.frameAfterDismiss
                    if animation == .fade {
                        self.webView?.alpha = 0.0
                    }
                    if let bgView = self.transparentBackgroundView {
                        bgView.backgroundColor = self.settings?.getBackgroundColor(opacity: 0.0)
                    }
                }) { _ in
                    if let bgView = self.transparentBackgroundView {
                        bgView.removeFromSuperview()
                    } else {
                        self.webView?.removeFromSuperview()
                    }
                    if shouldDeallocateWebView {
                        self.webView = nil
                    } else {
                        self.webView?.frame = self.frameBeforeShow
                    }
                }
            } else {
                if let bgView = self.transparentBackgroundView {
                    bgView.removeFromSuperview()
                } else {
                    self.webView?.removeFromSuperview()
                }
                if shouldDeallocateWebView {
                    self.webView = nil
                } else {
                    self.webView?.frame = self.frameBeforeShow
                }
            }
        }
    }
}
