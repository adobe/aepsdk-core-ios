# AEPCore

## About this project

The Mobile Core represents the core Adobe Experience Platform SDK that is required for every app implementation. The core contains a common set of functionality and frameworks, such as  Experience Cloud Identity services, data event hub, Rules Engine, reusable networking, disk access routines, and so on, which are required by all Adobe and third-party extensions.

## Requirements
- Xcode 11.x
- Swift 5.x

## Installation
These are currently the supported installation options:

### Manual
Include the AEPCore.xcodeproj into the project, and link all the needed targets to your app.

### Binaries
Run `make archive`, it will generates the .xcframeworks under the `build` folder. Drag and drop all the .xcframeworks to your app target.

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)
```ruby
# Podfile
use_frameworks!

# for app development, include all the following pods
target 'YOUR_TARGET_NAME' do
    pod 'AEPServices', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'main'
    pod 'AEPCore', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'main'
    pod 'AEPLifecycle', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'main'
    pod 'AEPIdentity', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'main'
    pod 'SwiftRulesEngine', :git => 'git@github.com:adobe/aepsdk-rulesengine-ios.git', :branch => 'dev'
end

# for extension development, include AEPCore and its dependencies
target 'YOUR_TARGET_NAME' do
    pod 'AEPCore', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'main'
    pod 'AEPServices', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'main'
    pod 'SwiftRulesEngine', :git => 'git@github.com:adobe/aepsdk-rulesengine-ios.git', :branch => 'dev'
end
```

Replace `YOUR_TARGET_NAME` and then, in the `Podfile` directory, type:

```bash
$ pod install
```

### [Carthage](https://github.com/Carthage/Carthage)
TBD

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

To add the AEPCore Package to your application, from the Xcode menu select:

`File > Swift Packages > Add Package Dependency...`

Enter the URL for the AEPCore package repository: `https://github.com/adobe/aepsdk-core-ios.git`.

When prompted, make sure you change the branch to `main`. (Once the repo is public, we will reference specific tags/versions instead of a branch)

Alternatively, if your project has a `Package.swift` file, you can add AEPCore directly to your dependencies:

```
dependencies: [
    .package(name: "AEPCore",
              url: "https://github.com/adobe/aepsdk-core-ios.git",
              from: "0.0.1")
]
```

## Current version
Adobe Experience Platform in Swift is currently in development.

### Contributing

Contributions are welcomed! Read the [Contributing Guide](./.github/CONTRIBUTING.md) for more information.

### Licensing

This project is licensed under the Apache V2 License. See [LICENSE](LICENSE) for more information.
