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

import AEPCore
import AEPServices

struct NetworkAvailabilityView: View {
    @State private var healthCheckEndpoint: String = "https://www.google.com"
    @State private var requireHealthCheck: Bool = false
    @State private var configurationStatus: String = ""

    @State private var isNetworkAvailableResult: String = ""

    @State private var checkStatusResult: String = ""
    @State private var checkIsAvailableResult: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                configurationSection
                syncCheckSection
                asyncCheckSection
            }.padding()
        }
    }

    var configurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Check Configuration").bold()

            TextField("Health check endpoint", text: $healthCheckEndpoint)
                #if os(iOS)
                    .autocapitalization(.none)
                #endif
                .disableAutocorrection(true)

            Toggle("Require health check for isNetworkAvailable()", isOn: $requireHealthCheck)

            Button(action: {
                guard let url = URL(string: healthCheckEndpoint) else {
                    configurationStatus = "Invalid endpoint URL"
                    return
                }
                let healthCheck = NetworkHealthCheckConfiguration(endpoint: url)
                let configuration = NetworkAvailabilityConfiguration(healthCheck: healthCheck,
                                                                      requireHealthCheckWhenConfigured: requireHealthCheck)
                MobileCore.setNetworkAvailabilityConfiguration(configuration)
                configurationStatus = "Applied: \(url.absoluteString), requireHealthCheck: \(requireHealthCheck)"
            }) {
                Text("Apply Configuration")
            }.buttonStyle(CustomButtonStyle())

            Button(action: {
                MobileCore.resetNetworkAvailabilityProvider()
                configurationStatus = "Reset to defaults"
                isNetworkAvailableResult = ""
                checkStatusResult = ""
                checkIsAvailableResult = ""
            }) {
                Text("Reset to Defaults")
            }.buttonStyle(CustomButtonStyle())

            if !configurationStatus.isEmpty {
                Text(configurationStatus)
            }
        }
    }

    var syncCheckSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Synchronous Check").bold()
            Text("Uses device path monitoring and, if configured, the last cached health check result.")
                .font(.caption)

            Button(action: {
                isNetworkAvailableResult = MobileCore.isNetworkAvailable() ? "Available" : "Not Available"
            }) {
                Text("Check isNetworkAvailable()")
            }.buttonStyle(CustomButtonStyle())

            if !isNetworkAvailableResult.isEmpty {
                Text("Result: \(isNetworkAvailableResult)")
            }
        }
    }

    var asyncCheckSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Asynchronous Check").bold()
            Text("Performs a fresh evaluation, including a live health check against the configured endpoint.")
                .font(.caption)

            Button(action: {
                MobileCore.checkNetworkAvailability { result in
                    DispatchQueue.main.async {
                        checkStatusResult = "\(result.status)"
                        checkIsAvailableResult = result.isAvailable ? "Available" : "Not Available"
                    }
                }
            }) {
                Text("Check Network Availability")
            }.buttonStyle(CustomButtonStyle())

            if !checkStatusResult.isEmpty {
                Text("Status: \(checkStatusResult)")
                Text("Is Available: \(checkIsAvailableResult)")
            }
        }
    }
}

struct NetworkAvailabilityView_Previews: PreviewProvider {
    static var previews: some View {
        NetworkAvailabilityView()
    }
}
