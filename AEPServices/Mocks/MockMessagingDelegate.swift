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
    import AEPServices

    public class MockMessagingDelegate: MessagingDelegate {
        var onShowCalled = false
        var onDismissCalled = false
        var shouldShowMessageCalled = false
        var urlLoadedCalled = false
    
        var paramMessage: Showable? = nil
        var paramUrl: URL? = nil
    
        var valueShouldShowMessage = true
    
        public func onShow(message: Showable) {
            onShowCalled = true
            paramMessage = message
        }
    
        public func onDismiss(message: Showable) {
            onDismissCalled = true
            paramMessage = message
        }
    
        public func shouldShowMessage(message: Showable) -> Bool {
            shouldShowMessageCalled = true
            paramMessage = message
            return valueShouldShowMessage
        }
    
        public func urlLoaded(_ url: URL, byMessage message: Showable) {
            urlLoadedCalled = true
            paramUrl = url
            paramMessage = message
        }
    }
#endif
