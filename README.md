# Adobe Experience Platform Core SDK

[![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-core-ios?label=AEPCore&logo=apple&logoColor=white&color=orange&sort=semver)](https://cocoapods.org/pods/AEPCore)
[![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-core-ios?label=AEPServices&logo=apple&logoColor=white&color=orange&sort=semver)](https://cocoapods.org/pods/AEPServices)
[![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-core-ios?label=AEPLifecycle&logo=apple&logoColor=white&color=orange&sort=semver)](https://cocoapods.org/pods/AEPLifecycle)
[![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-core-ios?label=AEPIdentity&logo=apple&logoColor=white&color=orange&sort=semver)](https://cocoapods.org/pods/AEPIdentity)
[![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-core-ios?label=AEPSignal&logo=apple&logoColor=white&color=orange&sort=semver)](https://cocoapods.org/pods/AEPSignal)

[![SPM](https://img.shields.io/github/v/release/adobe/aepsdk-core-ios?label=SPM&logo=apple&logoColor=white&color=orange&sort=semver)](https://github.com/adobe/aepsdk-core-ios/releases)
[![CircleCI](https://img.shields.io/circleci/project/github/adobe/aepsdk-core-ios/master.svg?logo=circleci)](https://circleci.com/gh/adobe/workflows/aepsdk-core-ios)
[![Code Coverage](https://img.shields.io/codecov/c/github/adobe/aepsdk-core-ios/main.svg?logo=codecov)](https://codecov.io/gh/adobe/aepsdk-core-ios/branch/main)

## About this project

The `AEPCore`, `AEPServices`, and `AEPIdentity` extensions represent the foundation of the Adobe Experience Platform SDK - every app using the SDK must include them. These modules contain a common set of functionality and services which are required by all SDK extensions.

`AEPCore` contains implementation of the Event Hub. The Event Hub is the mechanism used for delivering events between the app and the SDK. The Event Hub is also used for sharing data between extensions.

`AEPServices` provides several reusable implementations needed for platform support, including networking, disk access, and database management.

`AEPIdentity` implements the integration with Adobe Experience Platform Identity services.

`AEPSignal` represents the Adobe Experience Platform SDK's `Signal` extension that allows marketers to send a "signal" to their apps to send data to external destinations or to open URLs. 

`AEPLifecycle` represents the Adobe Experience Platform SDK's `Lifecycle` extension that helps collect application Lifecycle metrics such as, application install or upgrade information, application launch and session information, device information, and any additional context data provided by the application developer. 

## Requirements
- Xcode 15 (or newer)
- Swift 5.1 (or newer)

## Installation
These are currently the supported installation options:

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)
```ruby
# Podfile
use_frameworks!

# for app development, include all the following pods
target 'YOUR_TARGET_NAME' do
    pod 'AEPCore'
    pod 'AEPLifecycle'
    pod 'AEPIdentity'
    pod 'AEPSignal'
end

# for extension development, include AEPCore and its dependencies
target 'YOUR_TARGET_NAME' do
    pod 'AEPCore'
end
```

Replace `YOUR_TARGET_NAME` and then, in the `Podfile` directory, type:

```bash
$ pod install
```

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

To add the AEPCore Package to your application, from the Xcode menu select:

`File > Swift Packages > Add Package Dependency...`

Enter the URL for the AEPCore package repository: `https://github.com/adobe/aepsdk-core-ios.git`.

When prompted, input a specific version or a range of versions, and choose all the `AEP*` libraries.

Alternatively, if your project has a `Package.swift` file, you can add AEPCore directly to your dependencies:

```
dependencies: [
    .package(url: "https://github.com/adobe/aepsdk-core-ios.git", .upToNextMajor(from: "5.0.0"))
]
```

### Project Reference

Include `AEPCore.xcodeproj` in the targeted Xcode project and link all necessary libraries to your app target.

### Binaries

Run `make archive` or `make archive-ios` from the root directory to generate `.xcframeworks` for each module. The `make archive` command will generate XCFrameworks which support iOS and tvOS, while `make archive-ios` will generate XCFrameworks for iOS alone. Once complete, the XCFrameworks can be found in the `build` folder. Drag and drop all `.xcframeworks` to your app target in Xcode.

## Documentation

Additional documentation for usage and SDK architecture can be found under the [Documentation](Documentation/README.md) directory.

## Related Projects

| Project | Latest Release | Github |
|---|---|---|
|  Rules Engine | [![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-rulesengine-ios?label=CocoaPods&logo=apple&logoColor=white&color=orange&sort=semver)](https://cocoapods.org/pods/AEPRulesEngine) [![SPM](https://img.shields.io/github/v/release/adobe/aepsdk-rulesengine-ios?label=SPM&logo=apple&logoColor=white&color=orange&sort=semver)](https://github.com/adobe/aepsdk-rulesengine-ios/releases) | [Link](https://github.com/adobe/aepsdk-rulesengine-ios) |
| [Profile](https://developer.adobe.com/client-sdks/documentation/profile/) | [![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-userprofile-ios?label=CocoaPods&logo=apple&logoColor=white&color=orange&sort=semver)](https://cocoapods.org/pods/AEPUserProfile) [![SPM](https://img.shields.io/github/v/release/adobe/aepsdk-userprofile-ios?label=SPM&logo=apple&logoColor=white&color=orange&sort=semver)](https://github.com/adobe/aepsdk-userprofile-ios/releases)| [Link](https://github.com/adobe/aepsdk-userprofile-ios) |
| [Adobe Experience Platform Edge Network](https://developer.adobe.com/client-sdks/documentation/edge-network/) |[![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-edge-ios?label=CocoaPods&logo=apple&logoColor=white&color=orange&sort=semver)](https://cocoapods.org/pods/AEPEdge) [![SPM](https://img.shields.io/github/v/release/adobe/aepsdk-edge-ios?label=SPM&logo=apple&logoColor=white&color=orange&sort=semver)](https://github.com/adobe/aepsdk-edge-ios/releases)| [Link](https://github.com/adobe/aepsdk-edge-ios) |
| [Identity for Edge Network](https://developer.adobe.com/client-sdks/documentation/identity-for-edge-network/) | [![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-edgeidentity-ios?label=CocoaPods&logo=apple&logoColor=white&color=orange&sort=semver)](https://cocoapods.org/pods/AEPEdgeIdentity) [![SPM](https://img.shields.io/github/v/release/adobe/aepsdk-edgeidentity-ios?label=SPM&logo=apple&logoColor=white&color=orange&sort=semver)](https://github.com/adobe/aepsdk-edgeidentity-ios/releases) | [Link](https://github.com/adobe/aepsdk-edgeidentity-ios) |
| [Consent for Edge Network](https://developer.adobe.com/client-sdks/documentation/consent-for-edge-network/) | [![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-edgeconsent-ios?label=CocoaPods&logo=apple&logoColor=white&color=orange&sort=semver)](https://cocoapods.org/pods/AEPEdgeConsent) [![SPM](https://img.shields.io/github/v/release/adobe/aepsdk-edgeconsent-ios?label=SPM&logo=apple&logoColor=white&color=orange&sort=semver)](https://github.com/adobe/aepsdk-edgeconsent-ios/releases) | [Link](https://github.com/adobe/aepsdk-edgeconsent-ios) |
| [Edge Bridge](https://developer.adobe.com/client-sdks/documentation/adobe-analytics/migrate-to-edge-network/) | [![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-edgebridge-ios?label=CocoaPods&logo=apple&logoColor=white&color=orange&sort=semver)](https://cocoapods.org/pods/AEPEdgeBridge) [![SPM](https://img.shields.io/github/v/release/adobe/aepsdk-edgebridge-ios?label=SPM&logo=apple&logoColor=white&color=orange&sort=semver)](https://github.com/adobe/aepsdk-edgebridge-ios/releases) | [Link](https://github.com/adobe/aepsdk-edgebridge-ios) |
| [Adobe Experience Platform Assurance](https://developer.adobe.com/client-sdks/documentation/platform-assurance-sdk/) | [![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-assurance-ios?label=CocoaPods&logo=apple&logoColor=white&color=orange&sort=semver)](https://cocoapods.org/pods/AEPAssurance) [![SPM](https://img.shields.io/github/v/release/adobe/aepsdk-assurance-ios?label=SPM&logo=apple&logoColor=white&color=orange&sort=semver)](https://github.com/adobe/aepsdk-assurance-ios/releases) | [Link](https://github.com/adobe/aepsdk-assurance-ios)
| [Places Service](https://developer.adobe.com/client-sdks/documentation/places/) | [![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-places-ios?label=CocoaPods&logo=apple&logoColor=white&color=orange&sort=semver)](https://cocoapods.org/pods/AEPPlaces) [![SPM](https://img.shields.io/github/v/release/adobe/aepsdk-places-ios?label=SPM&logo=apple&logoColor=white&color=orange&sort=semver)](https://github.com/adobe/aepsdk-places-ios/releases) | [Link](https://github.com/adobe/aepsdk-places-ios) |
| [Adobe Analytics](https://developer.adobe.com/client-sdks/documentation/adobe-analytics/) | [![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-analytics-ios?label=CocoaPods&logo=apple&logoColor=white&color=orange&sort=semver)](https://cocoapods.org/pods/AEPAnalytics) [![SPM](https://img.shields.io/github/v/release/adobe/aepsdk-analytics-ios?label=SPM&logo=apple&logoColor=white&color=orange&sort=semver)](https://github.com/adobe/aepsdk-analytics-ios/releases) | [Link](https://github.com/adobe/aepsdk-analytics-ios) |
| [Adobe Streaming Media for Edge Network](https://developer.adobe.com/client-sdks/documentation/media-for-edge-network/) | [![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-edgemedia-ios?label=CocoaPods&logo=apple&logoColor=white&color=orange&sort=semver)](https://cocoapods.org/pods/AEPEdgeMedia) [![SPM](https://img.shields.io/github/v/release/adobe/aepsdk-edgemedia-ios?label=SPM&logo=apple&logoColor=white&color=orange&sort=semver)](https://github.com/adobe/aepsdk-edgemedia-ios/releases) | [Link](https://github.com/adobe/aepsdk-edgemedia-ios) |
| [Adobe Analytics - Media Analytics for Audio & Video](https://developer.adobe.com/client-sdks/documentation/adobe-media-analytics/) | [![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-media-ios?label=CocoaPods&logo=apple&logoColor=white&color=orange&sort=semver)](https://cocoapods.org/pods/AEPMedia) [![SPM](https://img.shields.io/github/v/release/adobe/aepsdk-media-ios?label=SPM&logo=apple&logoColor=white&color=orange&sort=semver)](https://github.com/adobe/aepsdk-media-ios/releases) | [Link](https://github.com/adobe/aepsdk-media-ios) |
| [Adobe Audience Manager](https://developer.adobe.com/client-sdks/documentation/adobe-audience-manager/) | [![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-audience-ios?label=CocoaPods&logo=apple&logoColor=white&color=orange&sort=semver)](https://cocoapods.org/pods/AEPAudience) [![SPM](https://img.shields.io/github/v/release/adobe/aepsdk-audience-ios?label=SPM&logo=apple&logoColor=white&color=orange&sort=semver)](https://github.com/adobe/aepsdk-audience-ios/releases) | [Link](https://github.com/adobe/aepsdk-audience-ios) |
| [Adobe Journey Optimizer](https://developer.adobe.com/client-sdks/documentation/adobe-journey-optimizer/) | [![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-messaging-ios?label=CocoaPods&logo=apple&logoColor=white&color=orange&sort=semver)](https://cocoapods.org/pods/AEPMessaging) [![SPM](https://img.shields.io/github/v/release/adobe/aepsdk-messaging-ios?label=SPM&logo=apple&logoColor=white&color=orange&sort=semver)](https://github.com/adobe/aepsdk-messaging-ios/releases) | [Link](https://github.com/adobe/aepsdk-messaging-ios) |
| [Adobe Journey Optimizer - Decisioning](https://developer.adobe.com/client-sdks/documentation/adobe-journey-optimizer-decisioning/) | [![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-optimize-ios?label=CocoaPods&logo=apple&logoColor=white&color=orange&sort=semver)](https://cocoapods.org/pods/AEPOptimize) [![SPM](https://img.shields.io/github/v/release/adobe/aepsdk-optimize-ios?label=SPM&logo=apple&logoColor=white&color=orange&sort=semver)](https://github.com/adobe/aepsdk-optimize-ios/releases) | [Link](https://github.com/adobe/aepsdk-optimize-ios) |
| [Adobe Target](https://developer.adobe.com/client-sdks/documentation/adobe-target/) | [![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-target-ios?label=CocoaPods&logo=apple&logoColor=white&color=orange&sort=semver)](https://cocoapods.org/pods/AEPTarget) [![SPM](https://img.shields.io/github/v/release/adobe/aepsdk-target-ios?label=SPM&logo=apple&logoColor=white&color=orange&sort=semver)](https://github.com/adobe/aepsdk-target-ios/releases) | [Link](https://github.com/adobe/aepsdk-target-ios) |
| [Adobe Campaign Standard](https://developer.adobe.com/client-sdks/documentation/adobe-campaign-standard/) | [![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-campaign-ios?label=CocoaPods&logo=apple&logoColor=white&color=orange&sort=semver)](https://cocoapods.org/pods/AEPCampaign) [![SPM](https://img.shields.io/github/v/release/adobe/aepsdk-campaign-ios?label=SPM&logo=apple&logoColor=white&color=orange&sort=semver)](https://github.com/adobe/aepsdk-campaign-ios/releases) | [Link](https://github.com/adobe/aepsdk-campaign-ios) | 
[Adobe Campaign Classic](https://developer.adobe.com/client-sdks/documentation/adobe-campaign-classic/) | [![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-campaignclassic-ios?label=CocoaPods&logo=apple&logoColor=white&color=orange&sort=semver)](https://cocoapods.org/pods/AEPCampaignClassic) [![SPM](https://img.shields.io/github/v/release/adobe/aepsdk-campaignclassic-ios?label=SPM&logo=apple&logoColor=white&color=orange&sort=semver)](https://github.com/adobe/aepsdk-campaignclassic-ios/releases) | [Link](https://github.com/adobe/aepsdk-campaignclassic-ios) |
| AEP SDK Sample App for iOS | - |  [Link](https://github.com/adobe/aepsdk-sample-app-ios) |

## Contributing

Contributions are welcomed! Read the [Contributing Guide](./.github/CONTRIBUTING.md) for more information.

## Licensing

This project is licensed under the Apache V2 License. See [LICENSE](LICENSE) for more information.
