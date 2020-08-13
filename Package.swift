// swift-tools-version:5.0
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

import PackageDescription

let package = Package(
    name: "AEPCore",
    platforms: [.iOS(.v10), .tvOS(.v10)],
    products: [
        .library(name: "AEPCore", targets: ["AEPCore"]),
        .library(name: "AEPIdentity", targets: ["AEPIdentity"]),
        .library(name: "AEPLifecycle", targets: ["AEPLifecycle"]),
        .library(name: "AEPServices", targets: ["AEPServices"]),
        .library(name: "AEPSignal", targets: ["AEPSignal"]),
    ],
    targets: [
        .target(name: "AEPCore", path: "AEPCore/Sources", dependencies: ["SwiftRulesEngine"]),
        .target(name: "AEPIdentity", path: "AEPIdentity/Sources", dependencies: ["AEPCore", "AEPServices"]),
        .target(name: "AEPLifecycle", path: "AEPLifecycle/Sources", dependencies: ["AEPCore", "AEPServices"]),
        .target(name: "AEPServices", path: "AEPServices/Sources", dependencies: ["AEPCore"]),
        .target(name: "AEPSignal", path: "AEPSignal/Sources", dependencies: ["AEPCore", "AEPServices"]),
    ],
    dependencies: [
        .package(name: "SwiftRulesEngine", url: "https://github.com/adobe/aepsdk-rulesengine-ios.git"),
    ]
)
