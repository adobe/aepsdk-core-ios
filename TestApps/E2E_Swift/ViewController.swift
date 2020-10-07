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
import AEPServices
import SwiftUI
import Foundation


extension UserDefaults {
    public static func clear() {
        for _ in 0 ... 5 {
            for key in UserDefaults.standard.dictionaryRepresentation().keys {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
}


extension FileManager {

    func clearCache() {
        if let url = self.urls(for: .cachesDirectory, in: .userDomainMask).first {

            do {
                try self.removeItem(at: URL(fileURLWithPath: "\(url.relativePath)/com.adobe.module.signal"))
            } catch {
                print("ERROR DESCRIPTION: \(error)")
            }

            do {
                try self.removeItem(at: URL(fileURLWithPath: "\(url.relativePath)/com.adobe.module.identity"))
            } catch {
                print("ERROR DESCRIPTION: \(error)")
            }
            do {
                try self.removeItem(at: URL(fileURLWithPath: "\(url.relativePath)/com.adobe.mobile.diskcache", isDirectory: true))
            } catch {
                print("ERROR DESCRIPTION: \(error)")
            }

        }

    }

}


class ViewController: UIViewController {

    @IBOutlet weak var statusLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    @IBAction func clearUserDefaults(_ sender: Any) {
        UserDefaults.clear()
        FileManager.default.clearCache()
    }

    @IBAction func loadSDK(_ sender: Any) {
        MyExtension.EVENT_HUB_BOOTED = false
        self.statusLabel.text = "...."

        MobileCore.setLogLevel(level: .trace)
        MobileCore.registerExtensions([Identity.self, Lifecycle.self, Signal.self, MyExtension.self]) {}
        MobileCore.configureWith(appId: "94f571f308d5/07c3fc1109d1/launch-2f01e36464da-development")
        MobileCore.lifecycleStart(additionalContextData: nil)
        for _ in 0...10000{
            if MyExtension.EVENT_HUB_BOOTED {
                self.statusLabel.text = "Eventhub Booted"
                break
            }else{
                usleep(100)
            }
        }
    }

    @IBAction func testFirstLaunchRules(_ sender: Any) {
        if MyExtension.RULES_CONSEQUENCE_FOR_INSTALL_EVENT {
            self.statusLabel.text = "Install event got evaluated"
        }else {
            self.statusLabel.text = "Error"
        }
    }

    @IBAction func testAttachDataRules(_ sender: Any) {
        self.statusLabel.text = "...."
        MyExtension.TRACK_ACTION_EVENT_WITH_ATTACHED_DATA = false

        MobileCore.dispatch(event: Event(name: "track action event for attach data rule", type: "com.adobe.eventType.generic.track", source: "com.adobe.eventSource.requestContent", data: ["action" : "action"]))

        for _ in 0...1000{
            if MyExtension.TRACK_ACTION_EVENT_WITH_ATTACHED_DATA {
                self.statusLabel.text  = "Catch the track action event with attached data"
                break
            }else{
                usleep(100)
            }
        }

    }

    @IBAction func testModifyDataRules(_ sender: Any) {
        self.statusLabel.text = "...."
        MyExtension.TRACK_ACTION_EVENT_WITH_MODIFIED_DATA = false

        MobileCore.dispatch(event: Event(name: "track action event for modify data rule", type: "com.adobe.eventType.generic.track", source: "com.adobe.eventSource.requestContent", data: ["action" : "action", "contextdata": ["key1":"value1", "key2":"value2"]]))

        for _ in 0...1000{
            if MyExtension.TRACK_ACTION_EVENT_WITH_MODIFIED_DATA {
                self.statusLabel.text = "Catch the track action event with modified data"
                break
            }else{
                usleep(100)
            }
        }
    }

    @IBAction func testOpenUrl(_ sender: Any) {
        self.statusLabel.text = "...."
        MobileCore.dispatch(event: Event(name: "track action event to trigger signal (openURL) action", type: "com.adobe.eventType.generic.track", source: "com.adobe.eventSource.requestContent", data: ["action" : "openURL"]))
    }

    @IBAction func lifecycleStart(_ sender: Any) {
        self.statusLabel.text = "...."
        for _ in 0...1000{
            if MyExtension.LIFECYCLE_START_EVENT {
                self.statusLabel.text = "Catch lifecycle statusLabel.text event"
                break
            }else{
                usleep(100)
            }
        }
    }

    @IBAction func testSyncIdentifiers(_ sender: Any) {
        self.statusLabel.text = "...."
        Identity.syncIdentifier(identifierType: "idTypeSYNC", identifier: "idValueSYNC", authenticationState: MobileVisitorAuthenticationState.authenticated)
    }


}


