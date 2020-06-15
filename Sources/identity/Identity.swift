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
    
    /// Appends visitor information to the given URL.
    /// - Parameters:
    ///   - url: URL to which the visitor info needs to be appended. Returned as is if it is nil or empty.
    ///   - completion: closure which will be invoked once the updated url is available, along with an error if any occurred
    static func appendTo(url: URL?, completion: @escaping (URL?, Error?) -> ())
    
    /// Returns all customer identifiers which were previously synced with the Adobe Experience Cloud.
    /// - Parameter completion: closure which will be invoked once the customer identifiers are available.
    static func getIdentifiers(completion: @escaping ([Identifiable]?, Error?) -> ())
    
    /// Returns the Experience Cloud ID.
    /// - Parameter completion: closure which will be invoked once Experience Cloud ID is available.
    static func getExperienceCloudId(completion: @escaping  (String?) -> ())
    
    /// Updates the given customer ID with the Adobe Experience Cloud ID Service.
    /// - Parameters:
    ///   - identifierType: a unique type to identify this customer ID, should be non empty and non nil value
    ///   - identifier: the customer ID to set, should be non empty and non nil value
    ///   - authenticationState: a `MobileVisitorAuthenticationState` value
    static func syncIdentifier(identifierType: String, identifier: String, authenticationState: MobileVisitorAuthenticationState)
    
    /// Updates the given customer IDs with the Adobe Experience Cloud ID Service with authentication value of `MobileVisitorAuthenticationState.unknown`
    /// - Parameter identifiers: a dictionary containing identifier type as the key and identifier as the value, both identifier type and identifier should be non empty and non nil values.
    static func syncIdentifiers(identifiers: [String: String]?)
    
    /// Updates the given customer IDs with the Adobe Experience Cloud ID Service.
    /// - Parameters:
    ///   - identifiers: a dictionary containing identifier type as the key and identifier as the value, both identifier type and identifier should be non empty and non nil values.
    ///   - authenticationState: a `MobileVisitorAuthenticationState` value
    static func syncIdentifiers(identifiers: [String: String]?, authenticationState: MobileVisitorAuthenticationState)
    
    /// Gets Visitor ID Service identifiers in URL query string form for consumption in hybrid mobile apps.
    /// - Parameter completion: closure invoked with a value containing the visitor identifiers as a query string upon completion of the service request
    static func getUrlVariables(completion: @escaping (String?, Error?) -> ())
}
