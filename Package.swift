// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
    platforms: [.iOS(.v10)],
    products: [
        .library(name: "AEPCore", targets: ["AEPCore"]),
        .library(name: "AEPIdentity", targets: ["AEPIdentity"]),
        .library(name: "AEPLifecycle", targets: ["AEPLifecycle"]),
        .library(name: "AEPServices", targets: ["AEPServices"]),
        .library(name: "AEPSignal", targets: ["AEPSignal"])
    ],
    dependencies: [
        .package(url: "https://github.com/adobe/aepsdk-rulesengine-ios.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "AEPCore",
                dependencies: ["AEPServices", "AEPRulesEngine"],
                path: "AEPCore/Sources"),
        .target(name: "AEPIdentity",
                dependencies: ["AEPCore"],
                path: "AEPIdentity/Sources"),
        .target(name: "AEPLifecycle",
                dependencies: ["AEPCore"],
                path: "AEPLifecycle/Sources"),
        .target(name: "AEPServices",
                dependencies: [],
                path: "AEPServices/Sources"),
        .target(name: "AEPSignal",
                dependencies: ["AEPCore"],
                path: "AEPSignal/Sources"),
    ]
)
