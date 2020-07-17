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
import AEPServices

class IdentityHitProcessor: HitProcessable {
    private let LOG_TAG = "IdentityHitProcessor"
    
    let retryInterval = TimeInterval(30)
    private let responseHandler: (DataEntity, Data?) -> ()
    private var networkService: NetworkService {
        return AEPServiceProvider.shared.networkService
    }

    /// Creates a new `IdentityHitProcessor` where the `responseHandler` will be invoked after each successful processing of a hit
    /// - Parameter responseHandler: a function to be invoked with the `DataEntity` for a hit and the response data for that hit
    init(responseHandler: @escaping (DataEntity, Data?) -> ()) {
        self.responseHandler = responseHandler
    }

    // MARK: HitProcessable
    
    func processHit(entity: DataEntity, completion: @escaping (Bool) -> ()) {
        guard let data = entity.data, let identityHit = try? JSONDecoder().decode(IdentityHit.self, from: data) else {
            // failed to convert data to hit, unrecoverable error, move to next hit
            completion(true)
            return
        }

        let networkRequest = NetworkRequest(url: identityHit.url)
        networkService.connectAsync(networkRequest: networkRequest) { (connection) in
            self.handleNetworkResponse(entity: entity, hit: identityHit, connection: connection, completion: completion)
        }

    }

    // MARK: Helpers
    
    /// Handles the network response after a hit has been sent to the server
    /// - Parameters:
    ///   - entity: the data entity responsible for the hit
    ///   - connection: the connection returned after we make the network request
    ///   - completion: a completion block to invoke after we have handled the network response with true for success and false for failure (retry)
    private func handleNetworkResponse(entity: DataEntity, hit: IdentityHit, connection: HttpConnection, completion: @escaping (Bool) -> ()) {
        if connection.responseCode == 200 {
            // hit sent successfully
            Log.debug(label: "\(LOG_TAG):\(#function)", "Identity hit request with url %s sent successfully", hit.url.absoluteString)
            responseHandler(entity, connection.data)
            completion(true)
        } else if NetworkServiceConstants.RECOVERABLE_ERROR_CODES.contains(connection.responseCode ?? -1) {
            // retry this hit later
            Log.error(label: "\(LOG_TAG):\(#function)", "Retrying Identity hit, request with url %s failed with error %s and recoverable status code %d", hit.url.absoluteString, connection.error?.localizedDescription ?? "", connection.responseCode ?? -1)
            completion(false)
        } else {
            // unrecoverable error. delete the hit from the database and continue
            Log.error(label: "\(LOG_TAG):\(#function)", "Dropping Identity hit, request with url %s failed with error %s and status code %d", hit.url.absoluteString, connection.error?.localizedDescription ?? "", connection.responseCode ?? -1)
            responseHandler(entity, connection.data)
            completion(true)
        }
    }

}
