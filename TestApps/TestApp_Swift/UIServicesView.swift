/*
 Copyright 2024 Adobe. All rights reserved.
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

class AEPUIManager {
    static let shared: AEPUIManager = AEPUIManager()
    
    private let sampleHTML = """
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <script type="text/javascript">
            function callNative(action) {
                try {
                    // the name of the message handler is the same name that must be registered in native code.
                    // in this case the message name is "iOS"
                    webkit.messageHandlers.iOS.postMessage(action);                
                } catch(err) {
                    console.log(err);
                }
            }
        </script>
        <title>Responsive Webpage</title>
    </head>
    <body style="margin: 0; font-family: Arial, sans-serif; background-color: black; color: white;">
        <header style="background-color: #333; text-align: center; padding: 1rem;">
            <h1>Fictional Webpage</h1>
        </header>
        <main style="text-align: center;">
            <img src="https://picsum.photos/id/234/100/100" alt="Sample Image" style="max-width: 100%; height: auto; padding: 1rem; display: block; margin: 0 auto;">
            <button onclick="callNative('native callbacks are cool!')">Native callback!</button>
        </main>
    </body>
    </html>
    """
    
    lazy var floatingButton: FloatingButtonPresentable = {
        let button = ServiceProvider.shared.uiService.createFloatingButton(listener: self)
        button.setInitial(position: .topLeft)
        return button
    }()
    
    lazy var fullscreenMessage: FullscreenPresentable? = {
        let settings = MessageSettings()
        settings.setWidth(75)
        settings.setHeight(75)
        settings.setUiTakeover(true)
             
        let gestures: [MessageGesture] = [ .swipeUp, .swipeDown, .swipeLeft, .swipeRight, .tapBackground]
        let gesturesDictionary = Dictionary(uniqueKeysWithValues: gestures.map { ($0, URL(string: "https://adobe.com")!) })
        settings.setGestures(gesturesDictionary)
                
        settings.setDisplayAnimation(.top)
        settings.setDismissAnimation(.bottom)
        
        return ServiceProvider.shared.uiService.createFullscreenMessage?(payload: sampleHTML,
                                                                         listener: self,
                                                                         isLocalImageUsed: false,
                                                                         settings: settings)
    }()
}

extension AEPUIManager: FloatingButtonDelegate {
    func onTapDetected() {}
    
    func onPanDetected() {}
    
    func onShow() {}
    
    func onDismiss() {}
}

extension AEPUIManager: FullscreenMessageDelegate {
    func onShow(message: AEPServices.FullscreenMessage) {
        message.handleJavascriptMessage("iOS") { text in
            Log.debug(label: "UIServicesView", "Message from WebView: \(String(describing: text))")
        }
    }
    
    func onDismiss(message: AEPServices.FullscreenMessage) {}
    
    func overrideUrlLoad(message: AEPServices.FullscreenMessage, url: String?) -> Bool { return true }
    
    func onShowFailure() {}
}

struct UIServicesView: View {
    var body: some View {
        VStack {
            VStack {
                Text("Floating Button").bold()
                HStack {
                    Button(action: {
                        AEPUIManager.shared.floatingButton.show()
                    }) {
                        Text("Show")
                    }.buttonStyle(CustomButtonStyle())
                    Button(action: {
                        AEPUIManager.shared.floatingButton.dismiss()
                    }) {
                        Text("Dismiss")
                    }.buttonStyle(CustomButtonStyle())
                }
                    
            }
            VStack {
                Text("FullScreen Message").bold()
                HStack {
                    Button(action: {
                        AEPUIManager.shared.fullscreenMessage?.show()
                    }) {
                        Text("Show")
                    }.buttonStyle(CustomButtonStyle())
                    Button(action: {
                        AEPUIManager.shared.fullscreenMessage?.dismiss()
                    }) {
                        Text("Dismiss")
                    }.buttonStyle(CustomButtonStyle())
                }
                    
            }
        }
    }
}

struct UIServicesView_Previews: PreviewProvider {
    static var previews: some View {
        UIServicesView()
    }
}
