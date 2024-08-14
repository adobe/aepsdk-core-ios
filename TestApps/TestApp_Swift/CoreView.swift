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
    @State private var appID: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                configSection
                privacySection
                trackSection
                eventsSection
            }.padding()
        }
    }

    var configSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Configuration").bold()
            
            TextField("App ID", text: $appID)
            Button(action: {
                MobileCore.configureWith(appId: appID)
            }) {
                Text("Configure With AppID")
            }.disabled(appID.isEmpty)
            .buttonStyle(CustomButtonStyle())

            Button(action: {
                let path = Bundle.main.path(forResource: "ADBMobileConfig_custom", ofType: "json") ?? ""
                MobileCore.configureWith(filePath: path)
            }) {
                Text("Configure With FilePath")
            }.buttonStyle(CustomButtonStyle())

            Button(action: {
                MobileCore.updateConfigurationWith(configDict: ["custom_key": "custom_value"])
            }) {
                Text("Update Configuration")
            }.buttonStyle(CustomButtonStyle())
            
            Button(action: {
                MobileCore.clearUpdatedConfiguration()
            }) {
                Text("Clear Updated Configuration")
            }.buttonStyle(CustomButtonStyle())
        }
    }
    
    var privacySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Change Privacy Status").bold()
            
            Button(action: {
                MobileCore.setPrivacyStatus(.optedIn)
            }) {
                Text("Opted In")
            }.buttonStyle(CustomButtonStyle())

            Button(action: {
                MobileCore.setPrivacyStatus(.optedOut)
            }) {
                Text("Opted Out")
            }.buttonStyle(CustomButtonStyle())

            Button(action: {
                MobileCore.setPrivacyStatus(.unknown)
            }) {
                Text("Unknown")
            }.buttonStyle(CustomButtonStyle())

            HStack {
                Button(action: {
                    MobileCore.getPrivacyStatus { privacyStatus in
                        self.currentPrivacyStatus = "\(privacyStatus.rawValue)"
                    }
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

    var trackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Track").bold()
            Button(action: {
                MobileCore.track(state: "state", data: nil)
            }) {
                Text("Track State")
            }.buttonStyle(CustomButtonStyle())
            
            Button(action: {
                MobileCore.track(action: "action", data: nil)
            }) {
                Text("Track Action")
            }.buttonStyle(CustomButtonStyle())
            
            Button(action: {
                MobileCore.collectPii(["name":"Adobe Experience Platform"])
            }){
                Text("Collect PII")
            }.buttonStyle(CustomButtonStyle())
            
            Button(action: {
                MobileCore.setAdvertisingIdentifier("ad_id")
            }){
                Text("Set Advertising Identifier")
            }.buttonStyle(CustomButtonStyle())
            
            Button(action: {
                MobileCore.setPushIdentifier("device_token".data(using: .utf8))
            }){
                Text("Set Push Identifier")
            }.buttonStyle(CustomButtonStyle())
        }
    }

    var eventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Events").bold()
            Button("Dispatch Event") {
                let event = Event(name: "Sample Event", type: "type", source: "source", data: ["platform": "ios"])
                MobileCore.dispatch(event: event)
            }
            .buttonStyle(CustomButtonStyle())

            Button("Dispatch with Callback") {
                let event = Event(name: "Sample Event", type: "type", source: "source", data: ["platform": "ios"])
                MobileCore.dispatch(event: event) { _ in }
            }
            .buttonStyle(CustomButtonStyle())
        }
    }
}

struct CoreView_Previews: PreviewProvider {
    static var previews: some View {
        CoreView()
    }
}
