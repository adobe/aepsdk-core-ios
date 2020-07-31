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

public protocol UIHandling {
    
    /// Shows an Alert dialog with given configuration.
    /// - Parameters:
    ///   - title: title of Alert
    ///   - message: description of Alert.
    ///   - positiveButtonText: optional text of positive button.
    ///   - negativeButtonText: optional text of negative button.
    ///   - alertListener: optional listener for listening alert related events.
    func showAlert(withTitle title: String, message: String, positiveButtonText: String?, negativeButtonText:String?, alertListener: UIAlertListener?)
    
    /*
     Returns true if there is another message displayed at this time, false otherwise.
     The status is collected from the messages monitor and it applies if either
     an alert message or a full screen message is displayed at some point.
     */
    func isMessageDisplayed() -> Bool
}
