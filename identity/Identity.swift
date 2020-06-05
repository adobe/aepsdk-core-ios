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

/// Defines the public interface for the Identity extension
protocol Identity {
    static func appendTo(url: URL?, completion: @escaping (URL?) -> ())
    
    static func appendTo(url: URL?, completion: @escaping (URL?, Error?) -> ())
    
    static func getIdentifiers(completion: @escaping ([MobileVisitorId]?) -> ())
    
    static func getIdentifiers(completion: @escaping ([MobileVisitorId]?, Error?) -> ())
    
    static func getExperienceCloudId(completion: @escaping  (String?) -> ())
    
    static func syncIdentifier(identifierType: String, identifier: String, authenticationState: MobileVisitorAuthenticationState)
    
    static func syncIdentifiers(identifiers: [String: String]?)
    
    static func syncIdentifiers(identifiers: [String: String]?, authenticationState: MobileVisitorAuthenticationState)
    
    static func getUrlVariables(completion:@escaping (String?) -> ())
    
    static func getUrlVariables(completion: @escaping (String?, Error?) -> ())
}
