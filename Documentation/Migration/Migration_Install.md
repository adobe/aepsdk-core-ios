# Migrate an ACPCore iOS app to the latest AEPCore

This document describes how existing ACPCore customers can upgrade to the AEP Swift SDK without introducing any breaking changes. We have made upgrading seamless by providing a backward-compatible layer, which will ensure that an existing ACPCore implementation will be compatible with AEPCore.

## Upgrading

### Cocoapods

The easiest way to upgrade from ACPCore to AEPCore is by using Cocoapods. To upgrade, update the reference to `ACPCore` in the `Podfile`:

```diff
- pod 'ACPCore'
+ pod 'ACPCore', :git => 'https://github.com/adobe/aep-sdk-compatibility-ios.git', :branch => 'main'
```

 Then run `pod install` and build the project, now the project will be using the latest AEPCore SDK. Under the hood, this new podspec brings in the latest AEPCore SDK via Cocoapods.

#### Version Control

To control which version of AEPCore will be used when using this upgrade method, specify the versions in the `Podfile`.

```ruby
pod 'AEPServices', '1.0.0'
pod 'AEPCore', '1.0.0'
pod 'AEPLifecycle', '1.0.0'
pod 'AEPIdentity', '1.0.0'
pod 'AEPRulesEngine', '1.0.0'
pod 'ACPCore', :git => 'https://github.com/adobe/aep-sdk-compatibility-ios.git', :branch => 'main'
```

### Manual Installation
If Cocoapods is not an option, the compatibility layer can be built manually using the following commands:

```bash
git clone https://github.com/adobe/aep-sdk-compatibility-ios.git
cd aep-sdk-compatibility
make make-libs
```
After running these commands, the `.xcframework` can be found within the build directory. Drag and drop these into an Xcode project and ensure that "copy items if needed" is checked.

## Sample Apps

To download more examples of integrating the AEP Swift SDK via the Compatibility layer, head over to the sample apps.

[View Samples](https://github.com/adobe/aepsdk-compatibility-ios/tree/main/testApps)

## Next Steps

- Get familiar with the various APIs offered by the AEP SDK by checking out the [API usage documents](../Usage/README.md). 
- To leverage shared services offered by the AEP SDK, check out the [Services documentation](../Services/README.md).
- To build an extension on top of the AEP SDK, check out the [Building Extensions documentation](../EventHub/BuildingExtensions.md).
- Verify an SDK implementation with [Assurance](../Debugging.md).

