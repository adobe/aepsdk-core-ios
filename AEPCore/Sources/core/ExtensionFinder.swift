//
// Copyright 2025 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import Foundation
import AEPServices

/// Utility to find and return AEP extension classes available at runtime.
struct ExtensionFinder {
    private static let LOG_TAG = "ExtensionFinder"
    
    // EventHub automatically registers Configuration and the Placeholder extensions, don't include them to prevent duplicate registration warnings.
    private static let adobeExtensionClassNames = [
        "AEPIdentity.Identity",
        "AEPSignal.Signal",
        "AEPLifecycle.Lifecycle",
        "AEPAssurance.Assurance",
        "AEPUserProfile.UserProfile",
        "AEPAnalytics.Analytics",
        "AEPAudience.Audience",
        "AEPMedia.Media",
        "AEPTarget.Target",
        "AEPCampaign.Campaign",
        "AEPCampaignClassic.CampaignClassic",
        "AEPPlaces.Places",
        "AEPEdgeIdentity.Identity",
        "AEPEdgeConsent.Consent",
        "AEPEdge.Edge",
        "AEPEdgeMedia.Media",
        "AEPEdgeBridge.EdgeBridge",
        "AEPOptimize.Optimize",
        "AEPMessaging.Messaging",
    ]
    
    /// Returns a list of registered Adobe extension classes available at runtime.
    static func getExtensions() -> [NSObject.Type] {
        return adobeExtensionClassNames.compactMap { className in
            guard let cls = NSClassFromString(className) as? NSObject.Type else {
                return nil
            }
            Log.trace(label: Self.LOG_TAG, "Extension \(className) found.")
            return cls
        }
    }
}
