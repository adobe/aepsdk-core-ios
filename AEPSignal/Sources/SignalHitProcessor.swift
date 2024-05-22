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

class SignalHitProcessor: HitProcessing {
    private let LOG_TAG = "SignalHitProcessor"
    private var networkService: Networking {
        return ServiceProvider.shared.networkService
    }

    // MARK: - HitProcessing

    func retryInterval(for entity: DataEntity) -> TimeInterval {
        return TimeInterval(30)
    }

    func processHit(entity: DataEntity, completion: @escaping (Bool) -> Void) {
        guard let data = entity.data, let signalHit = try? JSONDecoder().decode(SignalHit.self, from: data) else {
            // we can't recover from this error since converting data failed, discard this hit
            completion(true)
            return
        }
        let timeoutRaw = signalHit.timeout ?? 0
        let timeout = timeoutRaw > 0 ? timeoutRaw : SignalConstants.Defaults.TIMEOUT
        var httpMethod: HttpMethod
        if signalHit.postBody?.isEmpty ?? true {
            httpMethod = .get
        } else {
            httpMethod = .post
        }

        var headers: [String: String] = [:]
        if let contentType = signalHit.contentType {
            headers[NetworkServiceConstants.Headers.CONTENT_TYPE] = contentType
        }

        let request = NetworkRequest(url: signalHit.url, httpMethod: httpMethod, connectPayload: signalHit.postBody ?? "", httpHeaders: headers, connectTimeout: timeout, readTimeout: timeout)

        networkService.connectAsync(networkRequest: request) { connection in
            self.handleNetworkResponse(hit: signalHit, connection: connection, completion: completion)
        }
    }

    // MARK: - Helpers

    /// Handles the network response after a hit has been sent to the server
    /// - Parameters:
    ///   - hit: the signal hit being processed
    ///   - connection: the connection returned after we make the network request
    ///   - completion: a completion block to invoke after we have handled the network response with true for success and false for failure (retry)
    private func handleNetworkResponse(hit: SignalHit, connection: HttpConnection, completion: @escaping (Bool) -> Void) {
        let urlString = "\(String(describing: hit.url.host))\(String(describing: hit.url.path))"
        if NetworkServiceConstants.HTTP_SUCCESS_CODES.contains(connection.responseCode ?? -1) {
            // hit sent successfully
            Log.debug(label: LOG_TAG, "Signal request successfully sent: \(hit.url.absoluteString) sent successfully")
            completion(true)
        } else if NetworkServiceConstants.RECOVERABLE_ERROR_CODES.contains(connection.responseCode ?? -1) {
            // retry this hit later
            Log.debug(label: LOG_TAG, "Signal request failed with recoverable error \(connection.error?.localizedDescription ?? "") and status code \(connection.responseCode ?? -1). Will retry sending the request later: \(hit.url.absoluteString)")
            completion(false)
        } else if let error = connection.error as? URLError, error.isRecoverable {
            // retry this hit later as the request failed with a recoverable transport error
            Log.debug(label: LOG_TAG, "Signal request failed with recoverable error \(connection.error?.localizedDescription ?? "") and status code \(connection.responseCode ?? -1). Will retry sending the request later: \(urlString)")
            completion(false)
        } else {
            // unrecoverable error. delete the hit from the database and continue
            Log.warning(label: LOG_TAG, "Signal request failed with unrecoverable error \(connection.error?.localizedDescription ?? "") and status code \(connection.responseCode ?? -1). It will be dropped from the queue: \(urlString)")
            completion(true)
        }
    }
}
