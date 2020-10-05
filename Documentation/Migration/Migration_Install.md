# Migrate your ACPCore iOS app to the latest AEPCore

If you are a current ACPCore user interested in upgrading to the latest AEPCore SDK, this guide describes how to upgrade. We have made upgrading seamless by providing a backward-compatible layer, which will ensure that your existing ACPCore implementation will be compatible with AEPCore.

## Upgrading

### Cocoapods

The easiest way to upgrade from ACPCore to AEPCore is by using Cocoapods. To upgrade, update your reference to `ACPCore` in your projects `Podfile` as such:

```diff
- pod 'ACPCore'
+ pod 'ACPCore', :git => 'https://github.com/adobe/aep-sdk-compatibility-ios.git', :branch => 'main'
```

 Then run `pod install` and build your project, and you will be using the latest AEPCore SDK. Under the hood, this new podspec brings in the latest AEPCore SDK via Cocoapods.

#### Version Control

You may be interested in controlling which version of AEPCore will be used when using this upgrade method. To do this, you specify the versions in your `Podfile`.

```ruby
pod 'AEPServices', '1.0.0'
pod 'AEPCore', '1.0.0'
pod 'AEPLifecycle', '1.0.0'
pod 'AEPIdentity', '1.0.0'
pod 'AEPRulesEngine', '1.0.0'
pod 'ACPCore', :git => 'https://github.com/adobe/aep-sdk-compatibility-ios.git', :branch => 'main'
```

### Manual Installation

If you would prefer not to use Cocoapods, you can build the library and manually include them into your project. To build the compatibility layer, you can use the following commands:

```bash
git clone https://github.com/adobe/aep-sdk-compatibility-ios.git
cd aep-sdk-compatibility
make make-libs
```

After running these commands, you can find the `.xcframework`'s within the build directory. Drag and drop these into your project and ensure that you have 
"copy items if needed" checked.

## Sample Apps

To download more examples of integrating the AEP Swift SDK via the Compatibility layer, head over to our sample apps.

[View Samples](https://github.com/adobe/aepsdk-compatibility-ios/tree/main/testApps)

## Next Steps

Now that you have the Compatibility layer installed you can build and run your app without making any implementation changes to the SDK. 

- Get familiar with the various APIs offered by the AEP SDK by checking out our [API usage documents](./Usage/). 
- If you want to leverage shared services offered by the AEP SDK, check out the [Services documentation](./Services/README.md).
- If you want to build an extension on-top of the AEP SDK, check out the [Building Extensions documentation](./EventHub/BuildingExtensions.md).
- Verify your implementation with [Assurance](https://aep-sdks.gitbook.io/docs/beta/project-griffon).

