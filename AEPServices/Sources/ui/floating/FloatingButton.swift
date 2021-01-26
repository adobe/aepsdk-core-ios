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

/// This class is used to create a floating button
@objc(AEPFloatingButton)
public class FloatingButton: NSObject {
    
    private let PREVIEW_BUTTON_WIDTH = 60
    private let PREVIEW_BUTTON_HEIGHT = 60

    private var singleTap: UITapGestureRecognizer?
    private var panner: UIPanGestureRecognizer?
    private var timer: Timer?
    private var buttonImageView: UIImageView?

    private var listener: FloatingButtonListening?

    public init(listener: FloatingButtonListening?) {
        self.listener = listener
    }

    /// Display the floating button on the screen
    public func display() {
        DispatchQueue.main.async {
            if !self.initFloatingButton() {
                return
            }
            
            if self.timer != nil {
                self.timer?.invalidate()
                self.timer = nil
            }
            
            self.timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(self.bringFloatingButtonToFront), userInfo: nil, repeats: true)
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.handleDeviceRotation), name: UIDevice.orientationDidChangeNotification, object: nil)
        }
    }
    
    /// Remove the floating button from the screen
    public func remove() {
        DispatchQueue.main.async {
            NotificationCenter.default.removeObserver(self)
            self.buttonImageView?.removeFromSuperview()
            self.buttonImageView = nil
        }
    }

    private func initFloatingButton() -> Bool {
        guard let newFrame: CGRect = getImageFrame() else {
            // todo add LOG
            return false
        }
        self.buttonImageView = UIImageView(frame: newFrame)

        // color
        guard let imageData: Data = Data.init(base64Encoded: UIUtils.ENCODED_BACKGROUND_PNG, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters) else {
            return false
        }
        let image = UIImage(data: imageData)
        self.buttonImageView?.image = image

        // other properties
        self.buttonImageView?.contentMode = .scaleAspectFit
        self.buttonImageView?.isOpaque = true
        //self.buttonImageView?.backgroundColor = .clear
        self.buttonImageView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]

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
            guard let screenBounds = keyWindow?.frame.size else {
                return false
            }
            UIView.animate(withDuration: 0.3, animations: {
                var finalFrame = buttonImageView.frame
                finalFrame.origin.x = (screenBounds.width - CGFloat(self.PREVIEW_BUTTON_WIDTH)) / 2
                buttonImageView.frame = finalFrame
            }, completion: nil)
        }
        return true
    }
    
    @objc private func panWasRecognized(recognizer: UIPanGestureRecognizer) {
        DispatchQueue.main.async {
            guard let draggedView: UIView = self.panner?.view else {
                // todo add LOG
                return
            }
            
            guard let offset = self.panner?.translation(in: draggedView.superview) else {
                // todo add LOG
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
            self.listener?.onTapDetected()
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
                // todo add LOG
                return
            }
            self.buttonImageView?.frame = newFrame
        }
    }
        
    private func getImageFrame() -> CGRect? {
        let frameTuple = UIUtils.getFrame()
        guard var newFrame: CGRect = frameTuple?.frame else { return nil }
        guard let screenBounds: CGSize = frameTuple?.screenBounds else { return nil }
        
        newFrame = CGRect(x: (Int(screenBounds.width) - PREVIEW_BUTTON_WIDTH) - 30 / 2, y: (Int(screenBounds.height) - PREVIEW_BUTTON_HEIGHT) / 2, width: PREVIEW_BUTTON_WIDTH, height: PREVIEW_BUTTON_HEIGHT)
        
        return newFrame
    }
}
