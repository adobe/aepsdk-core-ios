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
import AEPAssurance

struct ContentView: View {
    @State private var assuranceSessionUrl:String = ""
    
    var body: some View {
        VStack(alignment: HorizontalAlignment.leading, spacing: 12) {
            TextField("Copy Assurance Session URL to here", text: $assuranceSessionUrl)
            HStack {
                Button(action: {
                    // replace the url with the valid one generated on Assurance UI
                    if let url = URL(string: self.assuranceSessionUrl) {
                        Assurance.startSession(url: url)
                    }
                }){
                    Text("Connect")
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .font(.caption)
                }.cornerRadius(5)
            }
        }.padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
