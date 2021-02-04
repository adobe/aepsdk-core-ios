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

/// Fullscreen message lifecycle event listener
@objc(AEPAlertMessageDelegate) public protocol AlertMessageDelegate {
    /// Invoked on positive button clicks
    /// - Parameters:
    ///     - message: Alert message which is currently shown
    @objc(onPositiveResponseWithAlertMessage:)
    func onPositiveResponse(message: AlertMessage)

    /// Invoked on negative button clicks
    /// - Parameters:
    ///     - message: Alert message which is currently shown
    @objc(onNegativeResponseWithAlertMessage:)
    func onNegativeResponse(message: AlertMessage)

    /// Invoked when the alert message is displayed
    /// - Parameters:
    ///     - message: Alert message which is currently shown
    @objc(onShowWithAlertMessage:)
    func onShow(message: AlertMessage)

    /// Invoked when the alert message is dismissed
    /// - Parameters:
    ///     - message: Alert message which is currently dismissed
    @objc(onDismissWithAlertMessage:)
    func onDismiss(message: AlertMessage)
    
    ///
    /// Invoked when the alert failed to be displayed
    ///
    func onShowFailed()
}
