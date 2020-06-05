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

/// MobileVisitorId contains Visitor Id origin, identifier type, identifier value and authentication state.
class MobileVisitorId {
    var idOrigin: String?
    var idType: String?
    var identifier: String?
    var authenticationState: MobileVisitorAuthenticationState
    
    /// Creates a new `MobileVisitorId` with an origin, type, identifier, and authentication state
    /// - Parameters:
    ///   - idOrigin: origin of the identifier
    ///   - idType: type of the identifier
    ///   - identifier: the identifier
    ///   - authenticationState: the authentication state
    init(idOrigin: String?, idType: String?, identifier: String?, authenticationState: MobileVisitorAuthenticationState) {
        self.idOrigin = idOrigin
        self.idType = idType
        self.identifier = identifier
        self.authenticationState = authenticationState
    }
}
