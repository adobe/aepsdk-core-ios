/*
 Copyright 2026 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import SwiftUI
import AEPServices

/// Demonstrates `isNetworkAvailable()` from the `Networking` protocol.
///
/// The default implementation (backed by `NWPathMonitor`) is accessed via
/// `ServiceProvider.shared.networkService.isNetworkAvailable()`.
/// A custom override registers a `Networking` conformer via the documented
/// `ServiceProvider.shared.networkService` override point.
private class CustomNetworkOverride: Networking {
    var forcedAvailability: Bool

    init(forcedAvailability: Bool) {
        self.forcedAvailability = forcedAvailability
    }

    func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)?) {
        let urlRequest = URLRequest(url: networkRequest.url)
        let task = URLSession(configuration: .default).dataTask(with: urlRequest) { data, response, error in
            completionHandler?(HttpConnection(data: data, response: response as? HTTPURLResponse, error: error))
        }
        task.resume()
    }

    func isNetworkAvailable() -> Bool {
        return forcedAvailability
    }
}

struct NetworkAvailabilityView: View {
    @State private var isNetworkAvailableResult: String = ""
    @State private var forcedAvailability: Bool = true
    @State private var overrideStatus: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                syncCheckSection
                overrideSection
            }.padding()
        }
    }

    var syncCheckSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Synchronous Check").bold()
            Text("Default implementation checks device-level NWPathMonitor status.")
                .font(.caption)

            Button(action: {
                let available = ServiceProvider.shared.networkService.isNetworkAvailable()
                isNetworkAvailableResult = available ? "Available" : "Not Available"
            }) {
                Text("Check isNetworkAvailable()")
            }.buttonStyle(CustomButtonStyle())

            if !isNetworkAvailableResult.isEmpty {
                Text("Result: \(isNetworkAvailableResult)")
            }
        }
    }

    var overrideSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Custom Override").bold()
            Text("Override isNetworkAvailable() in your own Networking conformer and register it via ServiceProvider.shared.networkService — the same override point used for HTTP transport customization.")
                .font(.caption)

            Toggle("Forced availability", isOn: $forcedAvailability)

            Button(action: {
                ServiceProvider.shared.networkService = CustomNetworkOverride(forcedAvailability: forcedAvailability)
                overrideStatus = "Applied: isNetworkAvailable() will now always report \(forcedAvailability)"
            }) {
                Text("Apply Custom Override")
            }.buttonStyle(CustomButtonStyle())

            if !overrideStatus.isEmpty {
                Text(overrideStatus)
            }
        }
    }
}

struct NetworkAvailabilityView_Previews: PreviewProvider {
    static var previews: some View {
        NetworkAvailabilityView()
    }
}
