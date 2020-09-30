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
import AEPIdentity
import AEPLifecycle
import AEPSignal
import SwiftUI
import Foundation

struct ContentView: View {
    @State var status = "..."
    var body: some View {
        HStack {
            Text(status)
        }
        VStack {

            Button(action: {
                MyExtension.EVENT_HUB_BOOTED = false
                self.status = "...."

                MobileCore.setLogLevel(level: .trace)
                MobileCore.registerExtensions([Identity.self, Lifecycle.self, Signal.self, MyExtension.self]) {}
                MobileCore.configureWith(appId: "94f571f308d5/07c3fc1109d1/launch-2f01e36464da-development")
                MobileCore.lifecycleStart(additionalContextData: nil)
                for _ in 0...10000{
                    if MyExtension.EVENT_HUB_BOOTED {
                        self.status = "Eventhub Booted"
                        break
                    }else{
                        usleep(100)
                    }
                }

            }) {
                Text("Load AEP SDK")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .font(.caption)
            }.cornerRadius(5)

            Button(action: {
                if MyExtension.RULES_CONSEQUENCE_FOR_INSTALL_EVENT {
                    self.status = "Install event got evaluated"
                }else {
                    self.status = "Error"
                }

            }) {
                Text("Verify First Launch Rule")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .font(.caption)
            }.cornerRadius(5)
            Button(action: {
                self.status = "...."
                MyExtension.TRACK_ACTION_EVENT_WITH_ATTACHED_DATA = false

                MobileCore.dispatch(event: Event(name: "track action event for attach data rule", type: "com.adobe.eventType.generic.track", source: "com.adobe.eventSource.requestContent", data: ["action" : "action"]))

                for _ in 0...1000{
                    if MyExtension.TRACK_ACTION_EVENT_WITH_ATTACHED_DATA {
                        self.status = "Catch the track action event with attached data"
                        break
                    }else{
                        usleep(100)
                    }
                }
            }) {
                Text("Verify Attach Data Rule")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .font(.caption)
            }.cornerRadius(5)
            Button(action: {
                self.status = "...."
                MyExtension.TRACK_ACTION_EVENT_WITH_MODIFIED_DATA = false

                MobileCore.dispatch(event: Event(name: "track action event for modify data rule", type: "com.adobe.eventType.generic.track", source: "com.adobe.eventSource.requestContent", data: ["action" : "action", "contextdata": ["key1":"value1", "key2":"value2"]]))

                for _ in 0...1000{
                    if MyExtension.TRACK_ACTION_EVENT_WITH_MODIFIED_DATA {
                        self.status = "Catch the track action event with modified data"
                        break
                    }else{
                        usleep(100)
                    }
                }
            }) {
                Text("Verify Modify Data Rule")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .font(.caption)
            }.cornerRadius(5)
            Divider()
            Button(action: {
                self.status = "...."
                for _ in 0...1000{
                    if MyExtension.LIFECYCLE_START_EVENT {
                        self.status = "Catch lifecycle start event"
                        break
                    }else{
                        usleep(100)
                    }
                }
            }) {
                Text("Verify Lifecycle Start Event")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .font(.caption)
            }.cornerRadius(5)
            Divider()
            Button(action: {
                self.status = "...."
                MobileCore.dispatch(event: Event(name: "track action event to trigger signal (openURL) action", type: "com.adobe.eventType.generic.track", source: "com.adobe.eventSource.requestContent", data: ["action" : "openURL"]))
            }) {
                Text("Verify Open URL")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .font(.caption)
            }.cornerRadius(5)
            Divider()
            Button(action: {
                self.status = "...."
                Identity.syncIdentifier(identifierType: "idTypeSYNC", identifier: "idValueSYNC", authenticationState: MobileVisitorAuthenticationState.authenticated)
            }) {
                Text("syncIdentifier")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .font(.caption)
            }.cornerRadius(5)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
