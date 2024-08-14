//
//  SignalView.swift
//  AEPCoreTestApp
//
//  Created by Praveen Vivekananthan on 8/12/24.
//  Copyright © 2024 Adobe. All rights reserved.
//

import SwiftUI
import AEPSignal
import AEPCore

struct SignalView: View {
    
    var body: some View {
        VStack(alignment: HorizontalAlignment.leading, spacing: 12) {
            Text("Signal extension version: \(Signal.extensionVersion)")
            Button(action: {
                // To test this, configure a rule in your launch property that triggers a postbackk for the following condition: a trackAction event with the action type 'trigger_postback'.
                MobileCore.track(action: "trigger_postback", data: nil)                               
            }) {
                Text("Trigger Post back")
            }.buttonStyle(CustomButtonStyle())
        }.padding()
    }
}

#Preview {
    SignalView()
}
