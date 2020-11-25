# Mobile Core API Usage

This document details all the APIs provided by MobileCore, along with sample code snippets on how to properly use the APIs.

For more in-depth information about the Mobile Core, visit the [offical SDK documentation on Mobile Core](https://aep-sdks.gitbook.io/docs/using-mobile-extensions/mobile-core).

## Importing Mobile Core

###### Swift

```swift
import MobileCore
```

###### Objective-C

```objective-c
@import AEPCore;
```

## API Usage

##### Getting MobileCore version:

###### Swift

```swift
let version = MobileCore.extensionVersion
```

###### Objective-C

```objective-c
NSString *version = [AEPMobileCore extensionVersion];
```

##### Registering multiple extensions and starting the SDK:

###### Swift

```swift
import AEPLifecycle
import AEPIdentity
import AEPSignal

// ...
MobileCore.registerExtensions([Lifecycle.self, Identity.self, Signal.self], {
   // handle completion
})
```

###### Objective-C

```objective-c
@import AEPLifecycle;
@import AEPIdentity;
@import AEPSignal;

// ...
NSArray *extensionsToRegister = @[AEPMobileIdentity.class, AEPMobileLifecycle.class, AEPMobileSignal.class];
[AEPMobileCore registerExtensions:extensionsToRegister completion:^{
    // handle completion
}];
```

##### Registering a single extension:

###### Swift

```swift
MobileCore.registerExtension(Lifecycle.self) {
    // handle completion
}
```

###### Objective-C

```objective-c
[AEPMobileCore registerExtension:AEPMobileLifecycle.class completion:^{
   // handle completion
}];
```

##### Unregistering a single extension:

###### Swift

```swift
MobileCore.unregisterExtension(Lifecycle.self) {
    // handle completion
}
```

###### Objective-C

```objective-c
[AEPMobileCore unregisterExtension:AEPMobileLifecycle.class completion:^{
    // handle completion
}];
```

##### Getting a list of registered extensions:

###### Swift

```swift
let registered = MobileCore.getRegisteredExtensions()
```

###### Objective-C

```objective-c
NSString *registered = [AEPMobileCore getRegisteredExtensions];
```

##### Configuring the SDK with an app id:

###### Swift

```swift
// Use the App id assigned to this application via Adobe Launch
MobileCore.configureWith(appId: "your-app-id")
```

###### Objective-C

```objective-c
// Use the App id assigned to this application via Adobe Launch
[AEPMobileCore configureWithAppId: @"your-app-id"];
```

##### Configuring the SDK with a bundled configuration file:

###### Swift

```swift
let filePath = Bundle.main.path(forResource: "ExampleJSONFile", ofType: "json")
MobileCore.configureWith(filePath: filePath)
```

###### Objective-C

```objective-c
NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ExampleJSONFile"ofType:@"json"];
[AEPMobileCore configureWithFilePath:filePath];
```

##### Programatically updating the configuration:

###### Swift

```swift
let updatedConfig = ["analytics.rsids": "your-rsids"]
MobileCore.updateConfigurationWith(configDict: updatedConfig)
```

###### Objective-C

```objective-c
NSDictionary *updatedConfig = @{ @"analytics.rsids": @"your-rsids"};
[AEPMobileCore updateConfiguration:updatedConfig];
```

##### Setting the privacy status:

`PrivacyStatus` is defined as:

```swift
@objc(AEPPrivacyStatus) public enum PrivacyStatus: Int, RawRepresentable, Codable {
    case optedIn = 0
    case optedOut = 1
    case unknown = 2
}
```

###### Swift

```swift
MobileCore.setPrivacy(status: .optedOut)
```

###### Objective-C

```objective-c
[AEPMobileCore setPrivacy:AEPPrivacyStatusOptedOut];
```

##### Reading the privacy status:

###### Swift

```swift
MobileCore.getPrivacyStatus { (privacyStatus) in
    // handle completion
}
```

###### Objective-C

```objective-c
[AEPMobileCore getPrivacyStatus:^(enum AEPPrivacyStatus privacyStatus) {
    // handle completion
}];
```

##### Setting the log level:

`LogLevel` is defined as:

```swift
@objc(AEPLogLevel) public enum LogLevel: Int, Comparable {
    case error = 0
    case warning = 1
    case debug = 2
    case trace = 3
}
```

###### Swift

```swift
MobileCore.setLogLevel(level: .trace)
```

###### Objective-C

```objective-c
[AEPMobileCore setLogLevel: AEPLogLevelTrace];
```

##### Starting a Lifecycle session:

###### Swift

```swift
MobileCore.lifecycleStart(additionalContextData: ["contextDataKey": "contextDataVal"])
```

###### Objective-C

```objective-c
[AEPMobileCore lifecycleStart:@{@"contextDataKey": @"contextDataVal"}];
```

##### Pausing a Lifecycle session:

###### Swift

```swift
MobileCore.lifecyclePause()
```

###### Objective-C

```objective-c
[AEPMobileCore lifecyclePause];
```

##### Dispatching an `Event`:

###### Swift

```swift
let event = Event(name: "My Event", type: EventType.custom, source: EventType.custom, data: ["exampleKey": "exampleVal"])
MobileCore.dispatch(event: event)
```

###### Objective-C

```objective-c
AEPEvent *event = [[AEPEvent alloc] initWithName:@"My Event" type:AEPEventType.custom source:AEPEventType.custom data:@{@"exampleKey": @"exampleVal"}];
[AEPMobileCore dispatch:event];
```

##### Dispatching an `Event` with a response callback:

###### Swift

```swift
let event = Event(name: "My Event", type: EventType.custom, source: EventType.custom, data: ["exampleKey": "exampleVal"])
MobileCore.dispatch(event: event) { (responseEvent) in
    // handle responseEvent
}
```

###### Objective-C

```objective-c
AEPEvent *event = [[AEPEvent alloc] initWithName:@"My Event" type:AEPEventType.custom source:AEPEventType.custom data:@{@"exampleKey": @"exampleVal"}];
[AEPMobileCore dispatch:event responseCallback:^(AEPEvent * _Nullable responseEvent) {
    // handle responseEvent
}];
```

##### Setting the advertising identifier:

###### Swift

```swift
MobileCore.setAdvertisingIdentifier(adId: "my-ad-id")
```

###### Objective-C

```objective-c
[AEPMobileCore setAdvertisingIdentifier:@"my-ad-id"];
```

##### Setting the push identifier:

###### Swift

```swift
// Set the deviceToken that the APNS has assigned to the device
MobileCore.setPushIdentifier(deviceToken: deviceToken)
```

###### Objective-C

```objective-c
// Set the deviceToken that the APNS has assigned to the device
[AEPMobileCore setPushIdentifier:deviceToken];
```

##### Setting the wrapper type:

`WrapperType` is defined as:

```swift
@objc(AEPWrapperType) public enum WrapperType: Int, RawRepresentable {
    case none = 0
    case reactNative = 1
    case flutter = 2
    case cordova = 3
    case unity = 4
    case xamarin = 5
}
```

###### Swift

```swift
MobileCore.setWrapperType(type: .flutter)
```

###### Objective-C

```objective-c
[AEPMobileCore setWrapperType:AEPWrapperTypeFlutter];
```

> Note: This API should only be used when implementing the SDK within a cross-platform solution such as React Native.

##### Setting the app group:

###### Swift

```swift
MobileCore.setAppGroup(group: "your-app-group")
```

###### Objective-C

```objective-c
[AEPMobileCore setAppGroup:@"your-app-group"];
```

##### Reading the SDK identities:

###### Swift

```swift
MobileCore.getSdkIdentities { (ids, error) in
    // handle completion
}
```

###### Objective-C

```objective-c
[AEPMobileCore getSdkIdentities:^(NSString * _Nullable ids, enum AEPError error) {
    // handle completion
}];
```

##### Collecting message info:

###### Swift

```swift
let messageInfo = ["testKey": "testVal"]
MobileCore.collectMessageInfo(messageInfo: messageInfo)
```

###### Objective-C

```objective-c
NSDictionary *messageInfo = @{@"testKey": @"testVal"}
[AEPMobileCore collectMessageInfo:messageInfo];
```

##### Collecting Pii:

###### Swift

```swift
let data = ["testKey": "testVal"]
MobileCore.collectPii(data: data)
```

###### Objective-C

```objective-c
NSDictionary *data = @{@"testKey": @"testVal"}
[AEPMobileCore collectPii:data];
```
