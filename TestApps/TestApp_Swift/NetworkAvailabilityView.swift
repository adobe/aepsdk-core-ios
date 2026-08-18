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

private let timeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm:ss"
    return f
}()

struct NetworkAvailabilityView: View {
    @State private var isAvailable: Bool? = nil
    @State private var lastChecked: Date? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                statusSection
                checkSection
            }
            .padding()
        }
        .onAppear { runCheck() }
    }

    // MARK: - Sections

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Current Status").font(.headline)
            HStack(spacing: 10) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 14, height: 14)
                Text(statusLabel)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor)
                Spacer()
                if let date = lastChecked {
                    Text("at \(timeFormatter.string(from: date))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }

    private var checkSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Check Now").font(.headline)
            Text("Reads the current network path from NWPathMonitor synchronously.")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Check isNetworkAvailable()") {
                runCheck()
            }
            .buttonStyle(CustomButtonStyle())
        }
    }

    // MARK: - Helpers

    private func runCheck() {
        isAvailable = ServiceProvider.shared.networkService.isNetworkAvailable()
        lastChecked = Date()
    }

    private var statusColor: Color {
        guard let available = isAvailable else { return .gray }
        return available ? .green : .red
    }

    private var statusLabel: String {
        guard let available = isAvailable else { return "Unknown" }
        return available ? "Available" : "Not Available"
    }
}

struct NetworkAvailabilityView_Previews: PreviewProvider {
    static var previews: some View {
        NetworkAvailabilityView()
    }
}
