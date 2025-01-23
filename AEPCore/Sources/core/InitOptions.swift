//
// Copyright 2023 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

@objc(AEPInitOptions)
public class InitOptions: NSObject {

    /// A unique identifier assigned to the app instance by Adobe Launch, passed to `MobileCore.configureWith(appId:)`
    @objc
    private(set) var appId: String?

    /// Absolute path to a local configuration file, passed to `MobileCore.configureWith(filePath:)`
    @objc
    private(set) var filePath: String?

    /// Flag indicating whether Lifecycle tracking is enabled automatically
    @objc public var lifecycleAutomaticTracking: Bool = true

    /// Additional context data for lifecycle tracking passed to `MobileCore.lifecycleStart(additionalContextData:)`
    @objc public var lifecycleAdditionalContextData: [String: Any]?

    /// App group used to share user defaults and files among containing app and extension apps. Passed to `MobleCore.setAppGroup()`
    @objc public var appGroup: String?

    /// Returns an instance of `InitOptions` without the configuration options of either `appId` or `filePath`.
    @objc
    public override init() {}

    /// Returns an instance of `InitOptions` with the given `appId`.
    /// Once initialized, configures the SDK by downloading the remote configuration file hosted on Adobe servers specified by the given application ID..
    @objc(initWithAppId:)
    public init(appId: String) {
        self.appId = appId
    }

    /// Returns an instance of `InitOptions` with the given `filePath`.
    /// Once initialized, configures the SDK by reading a local file containing the JSON configuration.
    @objc(initWithFilePath:)
    public init(filePath: String) {
        self.filePath = filePath
    }
}
