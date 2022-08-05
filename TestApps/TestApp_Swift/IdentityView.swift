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

import SwiftUI
import AEPCore
import AEPIdentity

struct IdentityView: View {

    @State private var experienceCloudId: String = ""
    @State private var trackingIdentifier: String = ""
    @State private var visitorIdentifier: String = ""
    @State private var urlVariables: String = ""
    @State private var sdkIdentities: String = ""
    @State private var url: String = "https://example.com"


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Identity APIs").bold()
                Button(action: {
                    MobileCore.setAdvertisingIdentifier("advertisingIdentifier")
                }) {
                    Text("Set Advertising Identifier")
                }.buttonStyle(CustomButtonStyle())

                Button(action: {
                    MobileCore.setPushIdentifier("9516258b6230afdd93cf0cd07b8dd845".data(using: .utf8))
                }) {
                    Text("Set Push Identifier")
                }.buttonStyle(CustomButtonStyle())

                Button(action: {
                    Identity.syncIdentifiers(identifiers: ["idType1":"1234567"], authenticationState: .authenticated)
                }) {
                    Text("Sync Identifiers")
                }.buttonStyle(CustomButtonStyle())
                Group {
                    Button(action: {
                        Identity.getExperienceCloudId { ecid, error in
                            self.experienceCloudId = ecid ?? ""
                        }
                    }) {
                        Text("Get ExperienceCloudId")
                    }.buttonStyle(CustomButtonStyle())
                    VStack {
                        Text("ExperienceCloudId:")
                        Text(self.experienceCloudId)
                    }
                }
                Group {
                    Button(action: {
                        MobileCore.getSdkIdentities { identities, _ in
                            self.sdkIdentities = identities ?? ""
                        }
                    }) {
                        Text("Get Sdk Identities")
                    }.buttonStyle(CustomButtonStyle())
                    VStack {
                        Text("SDK Identities:")
                        Text(self.sdkIdentities)
                    }
                }
                Group {
                    Button(action: {
                        Identity.getUrlVariables { variables, error in
                            self.urlVariables = variables ?? ""
                        }
                    }) {
                        Text("Get Url Variables")
                    }.buttonStyle(CustomButtonStyle())
                    VStack {
                        Text("URL Variables:")
                        Text(self.urlVariables)
                    }
                }
                Group {
                    Button(action: {
                        Identity.appendTo(url: URL(string: "https://example.com")) { url, _ in
                            self.url = url?.absoluteString ?? ""
                        }
                    }) {
                        Text("Append Url")
                    }.buttonStyle(CustomButtonStyle())
                    VStack {
                        Text("Appended Url")
                        Text(self.url)
                    }
                }
            }
        }
    }
}

struct IdentityView_Previews: PreviewProvider {
    static var previews: some View {
        IdentityView()
    }
}
