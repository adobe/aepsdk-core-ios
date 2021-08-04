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
public class FullscreenMessage: NSObject, FullscreenPresentable {

    /// Assignable in the constructor, `settings` control the layout and behavior of the message
    public var settings: MessageSettings?

    /// Native functions that can be called from javascript
    /// See `addHandler:forScriptMessage:`
    var scriptHandlers: [String: (Any?) -> Void] = [:]

    let LOG_PREFIX = "FullscreenMessage"
    private let DOWNLOAD_CACHE = "adbdownloadcache"
    private let HTML_EXTENSION = "html"
    private let TEMP_FILE_NAME = "temp"

    let fileManager = FileManager()

    var isLocalImageUsed = false
    var payload: String
    weak var listener: FullscreenMessageDelegate?
    public private(set) var webView: UIView?
    private var messageMonitor: MessageMonitoring

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
            self.dismissWithAnimation(animate: true, shouldDeallocateWebView: false)
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
        // check if the webview has already been created
        if let webview = webView as? WKWebView {
            // it has, determine if the monitor wants to show the message
            guard messageMonitor.show(message: self) else {
                listener?.onShowFailure()
                return
            }

            // notify global listeners
            self.listener?.onShow(message: self)
            self.messagingDelegate?.onShow(message: self)

            displayWithAnimation(webView: webview)
            return
        }

        DispatchQueue.main.async {
            // create the webview
            let wkWebView = self.getConfiguredWebView(newFrame: self.getFrame())

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

    /// Adds an entry to `scriptHandlers` for the provided message name.
    /// Handlers can be invoked from javascript in the message via
    /// - Parameters:
    ///   - name: the name of the message being passed from javascript
    ///   - handler: a method to be called when the javascript message is passed
    public func handleJavascriptMessage(_ name: String, withHandler handler: @escaping (Any?) -> Void) {
        // if the webview has already been created, we need to add the script handler to existing content controller
        if let webView = webView as? WKWebView {
            webView.configuration.userContentController.add(self, name: name)
        }

        scriptHandlers[name] = handler
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
        wkWebView.scrollView.layer.cornerRadius = 15
        wkWebView.backgroundColor = UIColor.clear
        wkWebView.isOpaque = false
        wkWebView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Fix for iPhone X to display content edge-to-edge
        if #available(iOS 11, *) {
            wkWebView.scrollView.contentInsetAdjustmentBehavior = .never
        }

        self.webView = wkWebView

        return wkWebView
    }

    private func displayWithAnimation(webView: WKWebView) {
        DispatchQueue.main.async {
            let keyWindow = UIApplication.shared.getKeyWindow()
            keyWindow?.addSubview(webView)
            let newY = webView.frame.origin.y - self.screenHeight
            UIView.animate(withDuration: 0.3, animations: {
                webView.frame.origin.y = newY
            }, completion: nil)
        }
    }

    private func dismissWithAnimation(animate: Bool, shouldDeallocateWebView: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: animate ? 0.3: 0, animations: {
                guard var webviewFrame = self.webView?.frame else {
                    return
                }
                webviewFrame.origin.y += self.screenHeight
                self.webView?.frame = webviewFrame
            }) { _ in
                self.webView?.removeFromSuperview()
                if shouldDeallocateWebView {
                    self.webView = nil
                }
            }
        }
    }

    /// Generates the correct frame for the webview based on `messageSettings`.
    ///
    /// Frame generation uses calculate variables `originX`, `originY`, `width`, and `height`.
    ///
    /// - Returns: a frame with the correct dimensions and origins based on `messageSettings`.
    private func getFrame() -> CGRect {
        var frame = CGRect(x: originX, y: originY, width: width, height: height)

        // add a one screen buffer if we're going to animate
        if let s = settings, s.animate {
            frame.origin.y += screenHeight
        }

        return frame
    }

    // returns the width of the screen, measured in points
    private var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }

    private var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }

    // width in settings represents a percentage of the screen.
    // e.g. - 80 = 80% of the screen width
    // default value is full screen width
    private var width: CGFloat {
        if let settingsWidth = settings?.width {
            return screenWidth * CGFloat(settingsWidth) / 100
        }

        return screenWidth
    }

    // height in settings represents a percentage of the screen.
    // e.g. - 80 = 80% of the screen height
    // default value is full screen height
    private var height: CGFloat {
        if let settingsHeight = settings?.height {
            return screenHeight * CGFloat(settingsHeight) / 100
        }

        return screenHeight
    }

    // x origin is calculated by settings values of horizontal alignment and horizontal inset
    // if horizontal alignment is center, horizontal inset is ignored and x is calculated so that the message will be
    // centered according to its width
    // if horizontal alignment is left or right, the inset will be calculated as a percentage width from the respective
    // alignment origin
    private var originX: CGFloat {
        // default to 0 for x origin if unspecified
        guard let settings = settings else {
            return 0
        }

        if settings.horizontalAlign == .left {
            // check for an inset, otherwise left alignment means return 0
            if let hInset = settings.horizontalInset {
                // since x alignment starts at 0 on the left, this value just needs to be
                // the percentage value translated to actual points
                return screenWidth * CGFloat(hInset) / 100
            } else {
                return 0
            }
        } else if settings.horizontalAlign == .right {
            // check for an inset
            if let hInset = settings.horizontalInset {
                // x alignment here is screen width - message width - inset value converted from percentage to points
                return screenWidth - width - (screenWidth * CGFloat(hInset) / 100)
            } else {
                // no inset, right x alignment means screen width - message width
                return screenWidth - width
            }
        }

        // handle center alignment, x is (screen width - message width) / 2
        return (screenWidth - width) / 2
    }

    // y origin is calculated by settings values of vertical alignment and vertical inset
    // if vertical alignment is center, vertical inset is ignored and y is calculated so that the message will be
    // centered according to its height
    // if vertical alignment is top or bottom, the inset will be calculated as a percentage height from the respective
    // alignment origin
    private var originY: CGFloat {
        // default to 0 for y origin if unspecified
        guard let settings = settings else {
            return 0
        }

        if settings.verticalAlign == .top {
            // check for an inset, otherwise top alignment means return 0
            if let vInset = settings.verticalInset {
                // since y alignment starts at 0 on the top, this value just needs to be
                // the percentage value translated to actual points
                return screenHeight * CGFloat(vInset) / 100
            } else {
                return 0
            }
        } else if settings.verticalAlign == .bottom {
            // check for an inset
            if let vInset = settings.verticalInset {
                // y alignment here is screen height - message height - inset value converted from percentage to points
                return screenHeight - height - (screenHeight * CGFloat(vInset) / 100)
            } else {
                // no inset, bottom y alignment means screen height - message height
                return screenHeight - height
            }
        }

        // handle center alignment, y is (screen height - message height) / 2
        return (screenHeight - height) / 2
    }
}
