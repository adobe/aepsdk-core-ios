/*
 Copyright 2024 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation
import SwiftUI

/// This class is used to create and display native fullscreen messages using SwiftUI.
@objc(AEPFullscreenMessageNative)
@available(iOSApplicationExtension, unavailable)
@available(tvOSApplicationExtension, unavailable)
@available(tvOS 13.0, *)
public class FullscreenMessageNative: NSObject, FullscreenPresentable {
    private let LOG_PREFIX = "FullscreenMessageNative"
    private let ANIMATION_DURATION = 0.3

    /// Assignable in the constructor, `settings` control the layout and behavior of the message
    @objc
    public var settings: MessageSettings?

    var payload: String
    var listener: FullscreenMessageNativeDelegate?
    private(set) var messageMonitor: MessageMonitoring
    private var hostingController: UIHostingController<FullscreenMessageView>?
    private var transparentBackgroundView: UIView?

    var messagingDelegate: MessagingDelegate? {
        return ServiceProvider.shared.messagingDelegate
    }

    /// Creates `FullscreenMessageNative` instance with the payload provided.
    /// - Parameters:
    ///     - payload: String content to be displayed with the message
    ///     - listener: `FullscreenMessageNativeDelegate` listener to listening the message lifecycle.
    ///     - messageMonitor: The message monitor to control message display
    ///     - settings: The `MessageSettings` object defining layout and behavior of the new message
    init(payload: String, listener: FullscreenMessageNativeDelegate?, messageMonitor: MessageMonitoring, settings: MessageSettings? = nil) {
        self.payload = payload
        self.listener = listener
        self.messageMonitor = messageMonitor
        self.settings = settings
    }

    /// Call this API to hide the fullscreen message.
    /// This API hides the fullscreen message with an animation, but it keeps the view for future reappearances.
    public func hide() {
        DispatchQueue.main.async {
            if self.messageMonitor.dismiss() == false {
                return
            }
            self.dismissWithAnimation(shouldDeallocateView: false)
        }
    }

    /// Attempt to create and show the in-app message.
    public func show() {
        show(withMessagingDelegateControl: true)
    }

    public func show(withMessagingDelegateControl delegateControl: Bool) {
        // get off main thread while delegate has control to prevent pause on main thread
        DispatchQueue.global().async {
            // only show the message if the monitor allows it
            let (shouldShow, error) = self.messageMonitor.show(message: self, delegateControl: delegateControl)
            guard shouldShow else {
                if let error = error {
                    self.listener?.onError?(message: self, error: error)
                }
                return
            }

            // notify global listeners
            self.listener?.onShow(message: self)
            self.messagingDelegate?.onShow(message: self)

            // dispatch UI activity back to main thread
            DispatchQueue.main.async {
                self.displayWithAnimation()
            }
        }
    }

    /// Call this API to dismiss the fullscreen message.
    /// This API removes the fullscreen message from memory.
    public func dismiss() {
        DispatchQueue.main.async {
            if self.messageMonitor.dismiss() == false {
                return
            }

            self.dismissWithAnimation(shouldDeallocateView: true)

            // notify all listeners
            self.listener?.onDismiss(message: self)
            self.messagingDelegate?.onDismiss(message: self)
        }
    }

    // MARK: - Private Methods

    private func displayWithAnimation() {
        DispatchQueue.main.async {
            let keyWindow = UIApplication.shared.getKeyWindow()

            // Create SwiftUI view
            let messageView = FullscreenMessageView(content: self.payload, settings: self.settings)
            let hostingController = UIHostingController(rootView: messageView)
            self.hostingController = hostingController

            if let animation = self.settings?.displayAnimation, animation != .none {
                let isFade = animation == .fade
                hostingController.view.alpha = isFade ? 0.0 : 1.0

                if let takeover = self.settings?.uiTakeover, takeover {
                    self.transparentBackgroundView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
                    self.transparentBackgroundView?.backgroundColor = self.settings?.getBackgroundColor(opacity: 0.0)
                    self.transparentBackgroundView?.addSubview(hostingController.view)
                    keyWindow?.addSubview(self.transparentBackgroundView!)
                } else {
                    keyWindow?.addSubview(hostingController.view)
                }

                UIView.animate(withDuration: self.ANIMATION_DURATION) {
                    hostingController.view.frame = self.frameWhenVisible
                    hostingController.view.alpha = 1.0
                    self.transparentBackgroundView?.backgroundColor = self.settings?.getBackgroundColor()
                }
            } else {
                hostingController.view.frame = self.frameWhenVisible
                keyWindow?.addSubview(hostingController.view)
            }
        }
    }

    private func dismissWithAnimation(shouldDeallocateView: Bool) {
        DispatchQueue.main.async {
            if let animation = self.settings?.dismissAnimation, animation != .none {
                UIView.animate(withDuration: self.ANIMATION_DURATION, animations: {
                    self.hostingController?.view.frame = self.frameAfterDismiss
                    if animation == .fade {
                        self.hostingController?.view.alpha = 0.0
                    }
                    if let bgView = self.transparentBackgroundView {
                        bgView.backgroundColor = self.settings?.getBackgroundColor(opacity: 0.0)
                    }
                }) { _ in
                    if let bgView = self.transparentBackgroundView {
                        bgView.removeFromSuperview()
                    } else {
                        self.hostingController?.view.removeFromSuperview()
                    }
                    if shouldDeallocateView {
                        self.hostingController = nil
                    } else {
                        self.hostingController?.view.frame = self.frameBeforeShow
                    }
                }
            } else {
                if let bgView = self.transparentBackgroundView {
                    bgView.removeFromSuperview()
                }

                self.hostingController?.view.removeFromSuperview()

                if shouldDeallocateView {
                    self.hostingController = nil
                } else {
                    self.hostingController?.view.frame = self.frameBeforeShow
                }
            }
        }
    }

    // MARK: - Frame Calculations

    private var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }

    private var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }

    private var frameBeforeShow: CGRect {
        return CGRect(x: 0, y: screenHeight, width: screenWidth, height: screenHeight)
    }

    private var frameWhenVisible: CGRect {
        return CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
    }

    private var frameAfterDismiss: CGRect {
        return CGRect(x: 0, y: -screenHeight, width: screenWidth, height: screenHeight)
    }
}

// MARK: - SwiftUI View

@available(tvOS 13.0, *)
struct FullscreenMessageView: View {
    let content: String
    let settings: MessageSettings?

    var body: some View {
        VStack {
            #if os(tvOS)
            Text(content)
                .foregroundColor(.white)
                .font(.system(size: 32)) // Larger font for TV
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(settings?.getBackgroundColor().color ?? Color.black)
                .cornerRadius(settings?.cornerRadius ?? 0)
            #else
            Text(content)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(settings?.getBackgroundColor().color ?? Color.black)
                .cornerRadius(settings?.cornerRadius ?? 0)
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Color Extension

@available(tvOS 13.0, *)
extension UIColor {
    var color: Color {
        return Color(self)
    }
}
