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

import AEPCore
import AEPServices
import Foundation

/// Defines the public interface for the Identity extension
@objc public extension Identity {
    /// Appends visitor information to the given URL.
    /// - Parameters:
    ///   - url: URL to which the visitor info needs to be appended. Returned as is if it is nil or empty.
    ///   - completion: closure which will be invoked once the updated url is available, along with an error if any occurred
    static func appendTo(url: URL?, completion: @escaping (URL?, Error?) -> Void) {
        let data = [IdentityConstants.EventDataKeys.BASE_URL: url?.absoluteString ?? ""]
        let event = Event(name: IdentityConstants.EventNames.IDENTITY_REQUEST_IDENTITY,
                          type: EventType.identity,
                          source: EventSource.requestIdentity,
                          data: data)

        MobileCore.dispatch(event: event) { responseEvent in
            guard let responseEvent = responseEvent else {
                completion(nil, AEPError.callbackTimeout)
                return
            }

            guard let updatedUrlStr = responseEvent.data?[IdentityConstants.EventDataKeys.UPDATED_URL] as? String else {
                completion(nil, AEPError.unexpected)
                return
            }
            completion(URL(string: updatedUrlStr), .none)
        }
    }

    /// Returns all customer identifiers which were previously synced with the Adobe Experience Cloud.
    /// - Parameter completion: closure which will be invoked once the customer identifiers are available.
    @objc(getIdentifiers:)
    static func getIdentifiers(completion: @escaping ([Identifiable]?, Error?) -> Void) {
        let event = Event(name: IdentityConstants.EventNames.IDENTITY_REQUEST_IDENTITY,
                          type: EventType.identity,
                          source: EventSource.requestIdentity,
                          data: nil)

        MobileCore.dispatch(event: event) { responseEvent in
            guard let responseEvent = responseEvent else {
                completion(nil, AEPError.callbackTimeout)
                return
            }

            guard let eventData: [String: Any] = responseEvent.data else {
                completion(nil, AEPError.unexpected)
                return
            }

            // return empty list if no Customer Identifiers in response data
            if eventData[IdentityConstants.EventDataKeys.VISITOR_IDS_LIST] == nil {
                completion([], nil)
                return
            }

            guard let identifiersDict = eventData[IdentityConstants.EventDataKeys.VISITOR_IDS_LIST] as? [[String: Any]] else {
                Log.warning(label: "\(IdentityConstants.EXTENSION_NAME):\(#function)", "Failed to retrieve visitor identifiers from event response as object type is not a map.")
                completion(nil, AEPError.unexpected)
                return
            }

            let identifiers = identifiersDict.map { CustomIdentity(dict: $0) }.compactMap { $0 }

            completion(identifiers, .none)
        }
    }

    /// Returns the Experience Cloud ID.
    /// - Parameter completion: closure which will be invoked once Experience Cloud ID is available.
    @objc(getExperienceCloudId:)
    static func getExperienceCloudId(completion: @escaping (String?, Error?) -> Void) {
        let event = Event(name: IdentityConstants.EventNames.IDENTITY_REQUEST_IDENTITY,
                          type: EventType.identity,
                          source: EventSource.requestIdentity,
                          data: nil)

        MobileCore.dispatch(event: event) { responseEvent in
            guard let responseEvent = responseEvent else {
                completion(nil, AEPError.callbackTimeout)
                return
            }

            guard let experienceCloudId = responseEvent.data?[IdentityConstants.EventDataKeys.VISITOR_ID_ECID] as? String else {
                completion(nil, AEPError.unexpected)
                return
            }

            completion(experienceCloudId, .none)
        }
    }

    /// Updates the given customer ID with the Adobe Experience Cloud ID Service.
    /// - Parameters:
    ///   - identifierType: a unique type to identify this customer ID, should be non empty and non nil value
    ///   - identifier: the customer ID to set, should be non empty and non nil value
    ///   - authenticationState: a `MobileVisitorAuthenticationState` value
    @objc(syncIdentifierWithType:identifier:authenticationState:)
    static func syncIdentifier(identifierType: String, identifier: String, authenticationState: MobileVisitorAuthenticationState) {
        syncIdentifiers(identifiers: [identifierType: identifier], authenticationState: authenticationState)
    }

    /// Updates the given customer IDs with the Adobe Experience Cloud ID Service with authentication value of `MobileVisitorAuthenticationState.unknown`
    /// - Parameter identifiers: a dictionary containing identifier type as the key and identifier as the value, both identifier type and identifier should be non empty and non nil values.
    @objc(syncIdentifiers:)
    static func syncIdentifiers(identifiers: [String: String]?) {
        syncIdentifiers(identifiers: identifiers, authenticationState: .unknown)
    }

    /// Updates the given customer IDs with the Adobe Experience Cloud ID Service.
    /// - Parameters:
    ///   - identifiers: a dictionary containing identifier type as the key and identifier as the value, both identifier type and identifier should be non empty and non nil values.
    ///   - authenticationState: a `MobileVisitorAuthenticationState` value
    @objc(syncIdentifiers:authenticationState:)
    static func syncIdentifiers(identifiers: [String: String]?, authenticationState: MobileVisitorAuthenticationState) {
        var eventData = [String: Any]()
        eventData[IdentityConstants.EventDataKeys.IDENTIFIERS] = identifiers
        eventData[IdentityConstants.EventDataKeys.AUTHENTICATION_STATE] = authenticationState
        eventData[IdentityConstants.EventDataKeys.FORCE_SYNC] = false
        eventData[IdentityConstants.EventDataKeys.IS_SYNC_EVENT] = true

        let event = Event(name: IdentityConstants.EventNames.IDENTITY_REQUEST_IDENTITY,
                          type: EventType.identity,
                          source: EventSource.requestIdentity,
                          data: eventData)
        MobileCore.dispatch(event: event)
    }

    /// Gets Visitor ID Service identifiers in URL query string form for consumption in hybrid mobile apps.
    /// - Parameter completion: closure invoked with a value containing the visitor identifiers as a query string upon completion of the service request
    @objc(getUrlVariables:)
    static func getUrlVariables(completion: @escaping (String?, Error?) -> Void) {
        let event = Event(name: IdentityConstants.EventNames.IDENTITY_REQUEST_IDENTITY,
                          type: EventType.identity,
                          source: EventSource.requestIdentity,
                          data: [IdentityConstants.EventDataKeys.URL_VARIABLES: true])

        MobileCore.dispatch(event: event) { responseEvent in
            guard let responseEvent = responseEvent else {
                completion(nil, AEPError.callbackTimeout)
                return
            }

            let urlVariables = responseEvent.data?[IdentityConstants.EventDataKeys.URL_VARIABLES] as? String
            completion(urlVariables, .none)
        }
    }
}
