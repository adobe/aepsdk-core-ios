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
    import SwiftUI
#if os(iOS)
    import WebKit
#endif

    #if os(tvOS)
    private class FocusableImageView: UIImageView {
        override var canBecomeFocused: Bool {
            return true
        }

        override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
            super.didUpdateFocus(in: context, with: coordinator)
            if context.nextFocusedView == self {
                // Button is focused
                self.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            } else if context.previouslyFocusedView == self {
                // Button lost focus
                self.transform = .identity
            }
        }
    }
    #endif

    /// This class is used to create a floating button
    @objc(AEPFloatingButton)
    @available(iOSApplicationExtension, unavailable)
    @available(tvOSApplicationExtension, unavailable)
    @available(tvOS 13.0, *)
    public class FloatingButton: NSObject, FloatingButtonPresentable {

        private let LOG_PREFIX = "FloatingButton"

        internal static let BUTTON_TOP_MARGIN = 40
        internal static let PREVIEW_BUTTON_WIDTH = 60
        internal static let PREVIEW_BUTTON_HEIGHT = 60

        private var singleTap: UITapGestureRecognizer?
        private var panner: UIPanGestureRecognizer?
        private var timer: Timer?
        private var buttonImageView: UIImageView?
        private var buttonPosition: FloatingButtonPosition = .center
        #if os(tvOS)
        private var fullscreenMessage: FullscreenPresentable?
        #endif

        private var listener: FloatingButtonDelegate?

        init(listener: FloatingButtonDelegate?) {
            self.listener = listener
            super.init()
            #if os(tvOS)
            // Create fullscreen message for tvOS
            let settings = MessageSettings()
            settings.setWidth(75)
            settings.setHeight(75)
            settings.setUiTakeover(true)
            settings.setDisplayAnimation(MessageAnimation.fade)
            settings.setDismissAnimation(MessageAnimation.fade)

            let sampleHTML = """
            <html>
            <head>
                <style>
                    body {
                        background-color: rgba(0, 0, 0, 0.8);
                        color: white;
                        font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                        padding: 20px;
                        text-align: center;
                    }
                    h1 {
                        font-size: 24px;
                        margin-bottom: 20px;
                    }
                    p {
                        font-size: 18px;
                        margin-bottom: 30px;
                    }
                    button {
                        background-color: #007AFF;
                        border: none;
                        border-radius: 8px;
                        color: white;
                        font-size: 18px;
                        padding: 12px 24px;
                        cursor: pointer;
                    }
                    button:hover {
                        background-color: #0056b3;
                    }
                </style>
            </head>
            <body>
                <h1>Welcome to tvOS</h1>
                <p>This is a sample message displayed when the floating button is tapped.</p>
                <button onclick="window.webkit.messageHandlers.iOS.postMessage('close')">Close</button>
            </body>
            </html>
            """

            if let uiService = ServiceProvider.shared.uiService as? AEPUIService {
                fullscreenMessage = uiService.createFullscreenMessage(payload: sampleHTML, listener: self, isLocalImageUsed: false, settings: settings)
            }
            #endif
        }

        /// Display the floating button on the screen
        public func show() {
            DispatchQueue.main.async {
                if !self.initFloatingButton() {
                    Log.debug(label: self.LOG_PREFIX, "Floating button couldn't be displayed, failed to create floating button.")
                    return
                }

                if self.timer != nil {
                    self.timer?.invalidate()
                    self.timer = nil
                }

                self.timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(self.bringFloatingButtonToFront), userInfo: nil, repeats: true)
#if os(iOS)
                NotificationCenter.default.addObserver(self, selector: #selector(self.handleDeviceRotation), name: UIDevice.orientationDidChangeNotification, object: nil)
#endif
            }
        }

        /// Remove the floating button from the screen
        public func dismiss() {
            DispatchQueue.main.async {
                // swiftlint:disable notification_center_detachment
                NotificationCenter.default.removeObserver(self)
                // swiftlint:enable notification_center_detachment
                self.buttonImageView?.removeFromSuperview()
                self.buttonImageView = nil
                self.listener?.onDismiss()
            }
        }

        public func setButtonImage(imageData: Data) {
            let image = UIImage(data: imageData)
            DispatchQueue.main.async {
                self.buttonImageView?.image = image
            }
        }

        public func setInitial(position: FloatingButtonPosition) {
            buttonPosition = position
        }

        private func initFloatingButton() -> Bool {
            guard let newFrame: CGRect = getImageFrame() else {
                Log.debug(label: LOG_PREFIX, "Floating button couldn't be displayed, failed to create a new frame.")
                return false
            }
            #if os(tvOS)
            self.buttonImageView = FocusableImageView(frame: newFrame)
            #else
            self.buttonImageView = UIImageView(frame: newFrame)
            #endif

            // color
            guard let imageData: Data = Data.init(base64Encoded: UIUtils.ENCODED_BACKGROUND_PNG, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters) else {
                Log.debug(label: LOG_PREFIX, "Floating button couldn't be displayed, background image for button is nil.")
                return false
            }
            let image = UIImage(data: imageData)
            self.buttonImageView?.image = image

            // other properties
            self.buttonImageView?.contentMode = .scaleAspectFit
            self.buttonImageView?.isOpaque = true
            self.buttonImageView?.backgroundColor = .clear
            self.buttonImageView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            // Make button focusable on tvOS
            #if os(tvOS)
            self.buttonImageView?.isUserInteractionEnabled = true
            // Add tap gesture for tvOS
            let tvOSTap = UITapGestureRecognizer(target: self, action: #selector(tapDetected))
            tvOSTap.allowedPressTypes = [NSNumber(value: UIPress.PressType.select.rawValue)]
            self.buttonImageView?.addGestureRecognizer(tvOSTap)
            #endif

            // gesture
            self.panner = UIPanGestureRecognizer(target: self, action: #selector(panWasRecognized))

            if let panner = self.panner {
                self.buttonImageView?.addGestureRecognizer(panner)
                self.buttonImageView?.isUserInteractionEnabled = true
            } else {
                // todo add LOG
                return false
            }

            self.singleTap = UITapGestureRecognizer(target: self, action: #selector(tapDetected))
            if let singleTap = self.singleTap {
                singleTap.numberOfTapsRequired = 1
                self.buttonImageView?.addGestureRecognizer(singleTap)
            }

            // view
            let keyWindow = UIApplication.shared.getKeyWindow()
            if let buttonImageView = self.buttonImageView {
                keyWindow?.addSubview(buttonImageView)
                keyWindow?.bringSubviewToFront(buttonImageView)

                // set the initial position for animation
                buttonImageView.frame.origin.x += CGFloat(FloatingButton.PREVIEW_BUTTON_WIDTH)
                // animate the x-axis of the button to its original position
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
                    buttonImageView.frame.origin.x -= CGFloat(FloatingButton.PREVIEW_BUTTON_WIDTH)
                }, completion: nil)

                // Notifying global listeners
                self.listener?.onShow()
            }
            return true
        }

        @objc private func panWasRecognized(recognizer: UIPanGestureRecognizer) {
            DispatchQueue.main.async {
                guard let draggedView: UIView = self.panner?.view else {
                    Log.debug(label: self.LOG_PREFIX, "Floating button couldn't be displayed, dragged view is nil.")
                    return
                }

                guard let offset = self.panner?.translation(in: draggedView.superview) else {
                    Log.debug(label: self.LOG_PREFIX, "Floating button couldn't be displayed, offset is nil.")
                    return
                }
                let center = draggedView.center
                draggedView.center = CGPoint(x: center.x + offset.x, y: center.y + offset.y)

                // Reset translation to zero so on the next `panWasRecognized:` message, the
                // translation will just be the additional movement of the touch since now.
                self.panner?.setTranslation(CGPoint(x: 0, y: 0), in: draggedView.superview)
                self.listener?.onPanDetected()
            }
        }

        @objc private func tapDetected(recognizer: UITapGestureRecognizer) {
            DispatchQueue.main.async {
                #if os(tvOS)
                // On tvOS, show the fullscreen message
                self.fullscreenMessage?.show()
                #else
                self.listener?.onTapDetected()
                #endif
            }
        }

        @objc private func bringFloatingButtonToFront(timer: Timer) {
            DispatchQueue.main.async {
                let keyWindow = UIApplication.shared.getKeyWindow()
                if let buttonImageView = self.buttonImageView {
                    keyWindow?.bringSubviewToFront(buttonImageView)
                }
            }
        }

        @objc private func handleDeviceRotation(notification: Notification) {
            DispatchQueue.main.async {
                guard let newFrame: CGRect = self.getImageFrame() else {
                    Log.debug(label: self.LOG_PREFIX, "Floating button couldn't be displayed, dragged view is nil.")
                    return
                }
                self.buttonImageView?.frame = newFrame
            }
        }

        private func getImageFrame() -> CGRect? {
            guard var newFrame: CGRect = UIUtils.getFrame() else { return nil }
            let size: CGSize? = newFrame.size

            if let screenBounds: CGSize = size {
                newFrame = buttonPosition.frame(screenBounds: screenBounds)
            }

            return newFrame
        }
    }

#if os(tvOS)
@available(tvOSApplicationExtension, unavailable)
extension FloatingButton: FullscreenMessageDelegate {
    public func onShow(message: FullscreenMessage) {
        // Handle show event
    }

    public func onDismiss(message: FullscreenMessage) {
        // Handle dismiss event
    }

    public func overrideUrlLoad(message: FullscreenMessage, url: String?) -> Bool {
        return true
    }

    public func onShowFailure() {
        // Handle show failure
    }
}
#endif
