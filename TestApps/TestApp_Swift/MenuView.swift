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

struct MenuView: View {
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Core Extensions")) {
                    NavigationLink(destination: CoreView().navigationBarTitle("Core")) {
                        Text("Core")
                    }

                    NavigationLink(destination: IdentityView().navigationBarTitle("Identity")) {
                        Text("Identity")
                    }
                    
                    NavigationLink(destination: LifecycleView().navigationBarTitle("Lifecycle")) {
                        Text("Lifecycle")
                    }
                }

                Section(header: Text("Validation")) {
                    NavigationLink(destination: AssuranceView().navigationBarTitle("Assurance")) {
                        Text("Assurance")
                    }
                }

            }.navigationBarTitle(Text("Extensions"))
        }
    }
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView()
    }
}
