# Adobe Experience Platform Core SDK

[![Cocoapods](https://img.shields.io/cocoapods/v/AEPCore.svg?color=orange&label=AEPCore&logo=apple&logoColor=white)](https://cocoapods.org/pods/AEPCore)
[![Cocoapods](https://img.shields.io/cocoapods/v/AEPServices.svg?color=orange&label=AEPServices&logo=apple&logoColor=white)](https://cocoapods.org/pods/AEPServices)
[![Cocoapods](https://img.shields.io/cocoapods/v/AEPLifecycle.svg?color=orange&label=AEPLifecycle&logo=apple&logoColor=white)](https://cocoapods.org/pods/AEPLifecycle)
[![Cocoapods](https://img.shields.io/cocoapods/v/AEPIdentity.svg?color=orange&label=AEPIdentity&logo=apple&logoColor=white)](https://cocoapods.org/pods/AEPIdentity)
[![Cocoapods](https://img.shields.io/cocoapods/v/AEPSignal.svg?color=orange&label=AEPSignal&logo=apple&logoColor=white)](https://cocoapods.org/pods/AEPSignal)

[![SPM](https://img.shields.io/badge/SPM-Supported-orange.svg?logo=apple&logoColor=white)](https://swift.org/package-manager/)
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
- Xcode 11.0 (or newer)
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
    .package(url: "https://github.com/adobe/aepsdk-core-ios.git", .upToNextMajor(from: "3.0.0"))
]
```

### Project Reference

Include `AEPCore.xcodeproj` in the targeted Xcode project and link all necessary libraries to your app target.

### Binaries

Run `make archive` from the root directory to generate `.xcframeworks` for each module under the `build` folder. Drag and drop all `.xcframeworks` to your app target in Xcode.

## Documentation

Additional documentation for usage and SDK architecture can be found under the [Documentation](Documentation/README.md) directory.

## Related Projects

| Project      | Description |
| ------------ | ----------- |
| [AEPEdge Extension](https://github.com/adobe/aepsdk-edge-ios) | Provides support to the Experience Platform Edge for the AEP SDK. |
| [AEPRulesEngine](https://github.com/adobe/aepsdk-rulesengine-ios) | Implementation of the Rules Engine used by the AEP SDK. |
| [AEP SDK Sample App for iOS](https://github.com/adobe/aepsdk-sample-app-ios) | Contains iOS sample apps for the AEP SDK. Apps are provided for both Objective-C and Swift implementations. |
| [AEP SDK Sample Extension for iOS](https://github.com/adobe/aepsdk-sample-extension-ios) | Contains a sample implementation of an iOS extension for the AEP SDK. Example implementations are provided for both Objective-C and Swift.
| [AEP SDK Compatibility for iOS](https://github.com/adobe/aepsdk-compatibility-ios) | Contains code that bridges `ACPCore` and 3rd party extension implementations into the AEP SDK runtime. |

## Contributing

Contributions are welcomed! Read the [Contributing Guide](./.github/CONTRIBUTING.md) for more information.

## Licensing

This project is licensed under the Apache V2 License. See [LICENSE](LICENSE) for more information.
