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

#if os(iOS)
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
        var payloadUsingLocalAssets: String?
        var listener: FullscreenMessageDelegate?
        public internal(set) var webView: UIView?
        private var tempHtmlFile: URL?
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
                if self.messageMonitor.dismiss() == false {
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
            show(withMessagingDelegateControl: true)
        }

        deinit {
            NotificationCenter.default.removeObserver(self)

            // remove the temporary html if it exists
            if let tempFile = self.tempHtmlFile {
                do {
                    try FileManager.default.removeItem(at: tempFile)
                    self.tempHtmlFile = nil
                } catch {
                    Log.debug(label: self.LOG_PREFIX, "Unable to remove temporary HTML file for dismissed in-app message: \(error)")
                }
            }
        }

        private var observerSet = false
        public func show(withMessagingDelegateControl delegateControl: Bool) {
            // check if the webview has already been created
            if let webview = self.webView as? WKWebView {
                self.handleShouldShow(webview: webview, delegateControl: delegateControl)
                return
            }

            DispatchQueue.main.async {

                // add observer to handle device rotation
                if !self.observerSet {
                    NotificationCenter.default.addObserver(self,
                                                           selector: #selector(self.handleDeviceRotation(notification:)),
                                                           name: UIDevice.orientationDidChangeNotification,
                                                           object: nil)
                    self.observerSet = true
                }

                // create the webview
                let wkWebView = self.getConfiguredWebView(newFrame: self.frameBeforeShow)

                // save the HTML payload to a local file if the cached image is being used
                var useTempHTML = false
                var cacheFolderURL: URL?
                let cacheFolder: URL? = self.fileManager.getCacheDirectoryPath()
                if cacheFolder != nil {
                    cacheFolderURL = cacheFolder?.appendingPathComponent(self.DOWNLOAD_CACHE)
                    let tempHTMLFileName = "\(self.TEMP_FILE_NAME)_\(self.hash)"
                    self.tempHtmlFile = cacheFolderURL?.appendingPathComponent(tempHTMLFileName).appendingPathExtension(self.HTML_EXTENSION)

                    if self.isLocalImageUsed, let file = self.tempHtmlFile {
                        // We have to use loadFileURL so we can allow read access to these image files in the cache but loadFileURL
                        // expects a file URL and not the string representation of the HTML payload. As a workaround, we can write the
                        // payload string to a temporary HTML file located at cachePath/adbdownloadcache/temp_[self.hash].html
                        // and pass that file URL to loadFileURL.
                        do {
                            try FileManager.default.createDirectory(atPath: cacheFolderURL?.path ?? "", withIntermediateDirectories: true, attributes: nil)
                            var tempHtml: Data?
                            // if a payload that uses local assets is defined, use it. otherwise, use the default payload.
                            if let localAssetsHtml = self.payloadUsingLocalAssets {
                                tempHtml = localAssetsHtml.data(using: .utf8, allowLossyConversion: false)
                            } else {
                                tempHtml = self.payload.data(using: .utf8, allowLossyConversion: false)
                            }
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
                    self.loadingNavigation = wkWebView.loadFileURL(URL(fileURLWithPath: self.tempHtmlFile?.path ?? ""), allowingReadAccessTo: URL(fileURLWithPath: cacheFolder?.path ?? ""))
                } else {
                    self.loadingNavigation = wkWebView.loadHTMLString(self.payload, baseURL: Bundle.main.bundleURL)
                }

                self.handleShouldShow(webview: wkWebView, delegateControl: delegateControl)
            }
        }

        @objc private func handleDeviceRotation(notification: NSNotification) {
            DispatchQueue.main.async {
                if self.transparentBackgroundView != nil {
                    self.transparentBackgroundView?.frame = CGRect(x: 0, y: 0, width: self.screenWidth, height: self.screenHeight + self.safeAreaHeight)
                }
                self.webView?.frame = self.frameWhenVisible
            }
        }

        private func handleShouldShow(webview: WKWebView, delegateControl: Bool) {
            // get off main thread while delegate has control to prevent pause on main thread
            DispatchQueue.global().async {
                // only show the message if the monitor allows it
                guard self.messageMonitor.show(message: self, delegateControl: delegateControl) else {
                    self.listener?.onShowFailure()
                    return
                }

                // notify global listeners
                self.listener?.onShow(message: self)
                self.messagingDelegate?.onShow(message: self)

                // dispatch UI activity back to main thread
                DispatchQueue.main.async {
                    self.displayWithAnimation(webView: webview)
                }
            }
        }

        public func dismiss() {
            DispatchQueue.main.async {
                // remove device orientation observer
                NotificationCenter.default.removeObserver(self)
                self.observerSet = false

                if self.messageMonitor.dismiss() == false {
                    return
                }

                self.dismissWithAnimation(shouldDeallocateWebView: true)

                // notify all listeners
                self.listener?.onDismiss(message: self)
                self.messagingDelegate?.onDismiss(message: self)

                // remove the temporary html if it exists
                if let tempFile = self.tempHtmlFile {
                    do {
                        try FileManager.default.removeItem(at: tempFile)
                        self.tempHtmlFile = nil
                    } catch {
                        Log.debug(label: self.LOG_PREFIX, "Unable to remove temporary HTML file for dismissed in-app message: \(error)")
                    }
                }
            }
        }

        /// Adds an entry to `scriptHandlers` for the provided message name.
        /// Handlers can be invoked from javascript in the message via
        /// - Parameters:
        ///   - name: the name of the message being passed from javascript
        ///   - handler: a method to be called when the javascript message is passed
        @objc public func handleJavascriptMessage(_ name: String, withHandler handler: @escaping (Any?) -> Void) {
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

        /// Generates an HTML payload pointing to the provided local assets
        ///
        /// This method loops through each entry of the provided `map`, and generates a new HTML payload by replacing
        /// occurrences of the key (the web URL for an image) with the value (the path to a file in local cache).
        ///
        /// - Parameter map: map containing image URLs and cached file paths
        @objc public func setAssetMap(_ map: [String: String]?) {
            guard let map = map, !map.isEmpty else {
                payloadUsingLocalAssets = nil
                return
            }

            payloadUsingLocalAssets = payload
            for asset in map {
                payloadUsingLocalAssets = payloadUsingLocalAssets?.replacingOccurrences(of: asset.key, with: asset.value)
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
            wkWebView.scrollView.backgroundColor = .clear
            wkWebView.backgroundColor = .clear
            wkWebView.isOpaque = false
            wkWebView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            // Fix for iPhone X to display content edge-to-edge
            if #available(iOS 11, *) {
                wkWebView.scrollView.contentInsetAdjustmentBehavior = .never
            }

            // if this is a ui takeover, add an invisible view over under the webview
            if let takeover = settings?.uiTakeover, takeover {
                transparentBackgroundView = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight + safeAreaHeight))
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

            webView = wkWebView

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
            // MOB-20427 - only display the WKWebView if we have html to show
            guard !self.payload.isEmpty else {
                Log.trace(label: self.LOG_PREFIX, "Suppressing the display of a FullscreenMessage because it has no HTML to be shown.")
                // reset the monitor so it doesn't think a message is being shown
                self.messageMonitor.dismissMessage()
                return
            }

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
                    }

                    self.webView?.removeFromSuperview()

                    if shouldDeallocateWebView {
                        self.webView = nil
                    } else {
                        self.webView?.frame = self.frameBeforeShow
                    }
                }
            }
        }
    }

#endif
