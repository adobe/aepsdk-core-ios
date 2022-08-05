/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import UIKit
import SwiftUI

import AEPCore

struct CoreView: View {
    @State private var currentPrivacyStatus: String = ""
    @State private var showingAlert = false
    @State private var retrievedAttributes: String = ""
    @State private var eventName: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                privacySection
                piiSection
                manualOverridesSection
                eventsSection
            }.padding()
        }
    }

    var privacySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Change Privacy Status").bold()
            Button(action: {
                // step-privacy-start
                MobileCore.setPrivacyStatus(.optedIn)
                // step-privacy-end
            }) {
                Text("Opted In")
            }.buttonStyle(CustomButtonStyle())

            Button(action: {
                // step-privacy-start
                MobileCore.setPrivacyStatus(.optedOut)
                // step-privacy-end
            }) {
                Text("Opted Out")
            }.buttonStyle(CustomButtonStyle())

            Button(action: {
                // step-privacy-start
                MobileCore.setPrivacyStatus(.unknown)
                // step-privacy-end
            }) {
                Text("Unknown")
            }.buttonStyle(CustomButtonStyle())

            HStack {
                Button(action: {
                    // step-privacy-start
                    MobileCore.getPrivacyStatus { privacyStatus in
                        self.currentPrivacyStatus = "\(privacyStatus.rawValue)"
                    }
                    // step-privacy-end
                }) {
                    Text("Get Privacy")
                }.buttonStyle(CustomButtonStyle())
                VStack{
                    Text("Current Privacy:")
                    Text(currentPrivacyStatus)
                }
            }
        }
    }

    var piiSection: some View {

        VStack(alignment: .leading, spacing: 12) {
            Text("Collect PII").bold()
            Button(action: {
                // step-pii-start
                MobileCore.collectPii(["name":"Adobe Experience Platform"])
                // step-pii-end
            }){
                Text("Collect PII")
            }.buttonStyle(CustomButtonStyle())
        }
    }


    var manualOverridesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Update Configuration").bold()
            Button(action: {
                // step-config-start
                let dataDict = ["analytics.batchLimit": 3]
                MobileCore.updateConfigurationWith(configDict: dataDict)
                // step-config-end
            }) {
                Text("Update Configuration")
            }.buttonStyle(CustomButtonStyle())
        }
    }

    var eventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dispatch Events").bold()
            Button(action: {
                let event = Event(name: "Sample Event", type: "type", source: "source", data: ["platform" : "ios"])
                MobileCore.dispatch(event: event)
            }) {
                Text("Dispatch Custom Event")
            }.buttonStyle(CustomButtonStyle())

            Button(action: {
                let event = Event(name: "Sample Event", type: "type", source: "source", data: ["platform" : "ios"])
                MobileCore.dispatch(event: event) { event in
                    self.eventName = event?.name ?? ""
                }
            }) {
                Text("Dispatch Custom Event with response callback")
            }.buttonStyle(CustomButtonStyle())
            VStack {
                Text("Custom Event Response:")
                Text(eventName)
            }
        }
    }
}

struct CoreView_Previews: PreviewProvider {
    static var previews: some View {
        CoreView()
    }
}
