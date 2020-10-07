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

struct ContentView: View {
    @State var status = "..."
    var body: some View {
        ScrollView{
            HStack {
                Text(status)
            }
            VStack {
                Button(action: {
                    PerfExtension.LIFECYCLE_START_RESPONSE_EVENT_RECEIVED = false
                    PerfExtension.EVENT_HUB_BOOTED = false
                    PerfExtension.RULES_CONSEQUENCE_EVENTS = 0
                    self.status = "...."

                    MobileCore.setLogLevel(level: .error)
                    MobileCore.registerExtensions([Identity.self, Lifecycle.self, Signal.self, PerfExtension.self]) {}
                    MobileCore.configureWith(appId: "94f571f308d5/fec7505defe0/launch-eaa54c95a6b5-development")
                    MobileCore.lifecycleStart(additionalContextData: nil)
                    for _ in 0...10000{
                        if PerfExtension.EVENT_HUB_BOOTED {
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
                    PerfExtension.EVENT_HUB_BOOTED = false
                    PerfExtension.RULES_CONSEQUENCE_EVENTS = 0
                    self.status = "...."

                    for _ in 0...99{
                        MobileCore.dispatch(event: Event(name: "mock event", type: "com.adobe.eventType.generic.track", source: "com.adobe.eventSource.requestContent", data: ["action" : "action"]))
                    }

                    for _ in 0...300000{
                        if PerfExtension.RULES_CONSEQUENCE_EVENTS >= 1000 {
                            self.status = "1000 Rules were Evaluated"
                            break
                        }else{
                            usleep(100)
                        }
                    }
                }) {
                    Text("Evaluate Rules")
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .font(.caption)
                }.cornerRadius(5)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
