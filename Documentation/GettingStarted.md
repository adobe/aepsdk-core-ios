# Getting Started

This guide walks through how to get up and running with the AEP Swift SDK with only a few lines of code.

> Existing ACP SDK customers should check out the [migration document](./Migration/ACP-Migration.md).

## Set up a Mobile Property

Set up a mobile property as outlined in the Adobe Experience Platform [docs](https://aep-sdks.gitbook.io/docs/getting-started/create-a-mobile-property)

## Get the Swift Mobile Core

Now that a Mobile Property is created, head over to the [install instructions](https://github.com/adobe/aepsdk-core-ios#installation) to install the SDK.

## Initial SDK Setup

1. Import each of the core extensions in the `AppDelegate` file:

```swift
import AEPCore
import AEPLifecycle
import AEPIdentity
import AEPSignal
```

2. Register the core extensions and configure the SDK with the assigned application identifier.
To do this, add the following code to the Application Delegate's `application(_:didFinishLaunchingWithOptions:)` method:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

 // Enable debug logging
 MobileCore.setLogLevel(level: .trace)

 MobileCore.registerExtensions([Lifecycle.self, Identity.self, Signal.self], {
 // Use the App id assigned to this application via Adobe Launch
 MobileCore.configureWith(appId: "appId")
  
 })  
 return true
}
```

## Implement Lifecycle Metrics

Lifecycle metrics is an optional, yet valuable feature provided by the Adobe Experience Platform SDK. It offers out-of-the-box, application lifecycle information about an app user. These metrics contain information on the app user's engagement lifecycle, such as device information, install or upgrade information, session start and pause times, and more.



Start Lifecycle data collection by calling `lifecycleStart:` from within the callback of `AEPCore.registerExtensions:`.

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

 // Enable debug logging
 MobileCore.setLogLevel(level: .trace)

 MobileCore.registerExtensions([Lifecycle.self, Identity.self, Signal.self], {
 // Use the App id assigned to this application via Adobe Launch
 MobileCore.configureWith(appId: "appId")
 if application.applicationState != .background {
  // Only start lifecycle if the application is not in the background
  MobileCore.lifecycleStart(additionalContextData: ["contextDataKey": "contextDataVal"])
 }
  
 })  
 return true
}
```

When launched, if an app is resuming from a backgrounded state, iOS might call the `applicationWillEnterForeground:` delegate method. It is also required to invoke `lifecycleStart:`.

```swift
func applicationWillEnterForeground(_ application: UIApplication) {  
 AEPCore.lifecycleStart(nil)
}
```

When the app enters the background, pause Lifecycle data collection from an app's `applicationDidEnterBackground:` delegate method:

```swift
func applicationDidEnterBackground(_ application: UIApplication) {  
 AEPCore.lifecyclePause()
}
```

## Sample Apps

To download more examples of integrating the AEP Swift SDK, head over to the sample app resources.

[View Samples](https://github.com/adobe/aepsdk-sample-app-ios)

## Next Steps

- Get familiar with the various APIs offered by the AEP SDK by checking out the [API usage documents](./Usage/). 
- Integrate with the [ Experience Platform Extension](https://github.com/adobe/aepsdk-platform-ios). 
- To leverage shared services offered by the AEP SDK, check out the [Services documentation](./Services/README.md).
- To build an extension on-top of the AEP SDK, check out the [Building Extensions documentation](./EventHub/BuildingExtensions.md).
