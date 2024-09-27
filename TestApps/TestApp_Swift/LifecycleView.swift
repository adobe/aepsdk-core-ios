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
import AEPLifecycle

struct LifecycleView: View {
    @State private var additionalDataKey:String = ""
    @State private var additionalDataValue: String = ""

    var body: some View {
        VStack(alignment: HorizontalAlignment.leading, spacing: 12) {
            Text("Lifecycle extension version: \(Lifecycle.extensionVersion)")

            Text("Additional Context Data")
            TextField("Key", text: $additionalDataKey)
            TextField("Value", text: $additionalDataValue)
            Button(action: {
                if additionalDataKey.isEmpty {
                    MobileCore.lifecycleStart(additionalContextData: nil)
                } else {
                    MobileCore.lifecycleStart(additionalContextData: [additionalDataKey:additionalDataValue])
                }
            }){
                Text("Lifecycle Start")
            }.buttonStyle(CustomButtonStyle())
            Button(action: {
                MobileCore.lifecyclePause()
            }) {
                Text("Lifecycle Pause")
            }.buttonStyle(CustomButtonStyle())

        }.padding()
    }
}

struct LifecycleView_Previews: PreviewProvider {
    static var previews: some View {
        LifecycleView()
    }
}
