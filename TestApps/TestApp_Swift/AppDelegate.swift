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
import AEPCore
import AEPServices
import AEPLifecycle
import AEPSignal
import AEPIdentity
import BackgroundTasks

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    private let LAUNCH_ENVIRONMENT_FILE_ID = ""

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let appState = application.applicationState
        MobileCore.setLogLevel(.trace)
        let extensions = [Identity.self,
                          Lifecycle.self,
                          Signal.self]

        MobileCore.registerExtensions(extensions, {
            MobileCore.configureWith(appId: self.LAUNCH_ENVIRONMENT_FILE_ID)

            // Enable for Production apps
            // if appState != .background {
            //      MobileCore.lifecycleStart(additionalContextData: nil)
            // }
        })

        // Sample for setting up a named SDK instance
        let sdkInstance1 = "sdkInstance1"
        MobileCore.initializeInstance(sdkInstance1)
        let core = MobileCore.api(for: sdkInstance1)
        core.registerExtensions(extensions) {
            // Use the same or a different app ID as the default instance
            core.configureWith(appId: self.LAUNCH_ENVIRONMENT_FILE_ID)
            
            // To track the lifecycle for sdkInstance1, uncomment the following lines
            // if appState != .background {
                // core.lifecycleStart(additionalContextData: nil)
            // }
        }

        // If testing background, edit test app scheme -> options -> background fetch -> Check "launch app due to background fetch event"
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "testBackground", using: nil) { task in
            // Check if we can retrieve from file from background
            self.backgroundTask()
            task.setTaskCompleted(success: true)
            self.scheduleAppRefresh()
        }
        return true
    }

    func backgroundTask() {
        // Provide the task you want to test in the background here
    }

    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "testBackground")

        request.earliestBeginDate = nil // Refresh after 5 minutes.

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh task \(error.localizedDescription)")
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

