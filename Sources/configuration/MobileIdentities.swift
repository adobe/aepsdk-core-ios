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

private struct CompanyContexts: Codable {
    let namespace = "imsOrgID"
    let marketingCloudId: String
}

private struct Users: Codable {
    let userIDs: [UserID]
}

private struct UserID: Codable {
    let namespace: String
    let value: String
    let type: String
}

struct MobileIdentities: Codable {
    
    typealias SharedStateProvider = (String, Event) -> ((value: [String: Any]?, status: SharedStateStatus))
    private var companyContexts: CompanyContexts?
    private var users: Users?
    
    mutating func getAllIdentifiers(event: Event, sharedStateProvider: SharedStateProvider) -> String? {
        if let companyContexts = getCompanyContexts(event: event, sharedStateProvider: sharedStateProvider) {
            self.companyContexts = companyContexts
        }
        
        var userIds = [UserID]()
        userIds.append(contentsOf: getVisitorIdentifiers(event: event, sharedStateProvider: sharedStateProvider))
        // TODO: Analytics
        // TODO: Audience
        // TODO: Target
        
        if !userIds.isEmpty {
            self.users = Users(userIDs: userIds)
        }
        
        guard let encodedSelf = try? JSONEncoder().encode(self), let jsonString = String(data: encodedSelf, encoding: .utf8) else { return nil }
        return jsonString
    }
    
    func areSharedStatesReady(event: Event, sharedStateProvider: SharedStateProvider) -> Bool {
        let identityStatus = sharedStateProvider(IdentityConstants.EXTENSION_NAME, event).status
        let configurationStatus = sharedStateProvider(IdentityConstants.EXTENSION_NAME, event).status
        // TODO: Analytics
        // TODO: Audience
        // TODO: Target
        return identityStatus == .set && configurationStatus == .set
    }
    
    // MARK: Private APIs
    
    private func getVisitorIdentifiers(event: Event, sharedStateProvider: SharedStateProvider) -> [UserID] {
        let identitySharedState = sharedStateProvider(IdentityConstants.EXTENSION_NAME, event)
        guard identitySharedState.status == .set else { return [] }

        var visitorIds = [UserID]()
        
        // marketing cloud id
        if let marketingCloudId = identitySharedState.value?[IdentityConstants.EventDataKeys.VISITOR_ID_MID] as? String {
            visitorIds.append(UserID(namespace: "4", value: marketingCloudId, type: "namespaceId"))
        }
        
        // visitor ids and advertising id
        // Identity sets the advertising identifier both in ‘visitoridslist’ and as ‘advertisingidentifer’ in the Identity shared state.
        // So, there is no need to fetch the advertising identifier with advertisingidentifer namespace DSID_20914 separately.
        if let customVisitorIds = identitySharedState.value?[IdentityConstants.EventDataKeys.VISITOR_IDS_LIST] as? [CustomIdentity] {
            // convert each `CustomIdentity` to a `UserID`, then remove any nil values
            visitorIds.append(contentsOf: customVisitorIds.map {$0.toUserID()}.compactMap {$0})
        }
        
        // push identifier
        if let pushId = identitySharedState.value?[IdentityConstants.EventDataKeys.PUSH_IDENTIFIER] as? String, !pushId.isEmpty {
            visitorIds.append(UserID(namespace: "20920", value: pushId, type: "integrationCode"))
        }
        
        return visitorIds
    }
    
    private func getCompanyContexts(event: Event, sharedStateProvider: SharedStateProvider) -> CompanyContexts? {
        let configurationSharedState = sharedStateProvider(ConfigurationConstants.EXTENSION_NAME, event)
        guard configurationSharedState.status == .set else { return nil }
        guard let marketingCloudOrgId = configurationSharedState.value?[ConfigurationConstants.Keys.EXPERIENCE_CLOUD_ORGID] as? String, !marketingCloudOrgId.isEmpty else { return nil }
        
        return CompanyContexts(marketingCloudId: marketingCloudOrgId)
    }
}

private extension CustomIdentity {
    func toUserID() -> UserID? {
        guard let type = type, let identifier = identifier, !identifier.isEmpty else { return nil }
        return UserID(namespace: type, value: identifier, type: "integrationCode")
    }
}
