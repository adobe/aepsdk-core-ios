# Getting Started

This guide walks through how to get up and running with the AEP Swift SDK with only a few lines of code.

> Existing ACP SDK customers should check out the [migration document](./Migration/Migration_Install.md).

## Set up a Mobile Property

Set up a mobile property as outlined in the Adobe Experience Platform [docs](https://aep-sdks.gitbook.io/docs/getting-started/create-a-mobile-property)

## Get the Swift Mobile Core

Now that a Mobile Property is created, head over to the [install instructions](https://github.com/adobe/aepsdk-core-ios#installation) to install the SDK.

## Initial SDK Setup using `initialize` API

The `initialize(appId:)` API, added in AEPCore version 5.4.0, will automatically register all extensions included with the application while also enabling Lifecycle data collection without additional code. Lifecycle data collection requires the AEPLifecycle extension included as a dependency to your application.

In the `AppDelegate` file:

```swift
import AEPCore

...

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
 MobileCore.setLogLevel(level: .trace)  // Enable debug logging

 MobileCore.initialize(appId: "your-app-id")
 return true
}
```

Manually calling the Lifecycle APIs `lifecycleStart(additionalContextData:)` and `lifecyclePause()` is not required when enabling automatic Lifecycle tracking using the `initialize(appId:)` API. If your application needs more control over the Lifecycle APIs, you can disable automatic Lifecycle tracking using the `InitOptions` object with the `initialize(options:)` API and [implementing the Lifecycle APIs](#implement-lifecycle-data-collection).

In the `AppDelegate` file:

```swift
import AEPCore

...

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
 MobileCore.setLogLevel(level: .trace)  // Enable debug logging

 let options = InitOptions(appId: "your-app-id")
 options.lifecycleAutomaticTrackingEnabled = false

 MobileCore.initialize(options: options, {
    // handle completion
 })
 return true
}
```

## Initial SDK Setup using `registerExtensions` API

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

## Implement Lifecycle data collection

Lifecycle metrics is an optional, yet valuable feature provided by the Adobe Experience Platform SDK. It offers out-of-the-box, application lifecycle information about an app user. These metrics contain information on the app user's engagement lifecycle, such as device information, install or upgrade information, session start and pause times, and more.



Start Lifecycle data collection by calling `lifecycleStart:` from within the callback of `MobileCore.registerExtensions:`.

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
 MobileCore.lifecycleStart(nil)
}
```

When the app enters the background, pause Lifecycle data collection from an app's `applicationDidEnterBackground:` delegate method:

```swift
func applicationDidEnterBackground(_ application: UIApplication) {  
 MobileCore.lifecyclePause()
}
```

## Sample Apps

To download more examples of integrating the AEP Swift SDK, head over to the sample app resources.

[View Samples](https://github.com/adobe/aepsdk-sample-app-ios)

## Next Steps

- Get familiar with the various APIs offered by the AEP SDK by checking out the [API usage documents](./Usage/README.md). 
- Integrate with the [ Experience Platform Extension](https://github.com/adobe/aepsdk-platform-ios). 
- Validate SDK implementation with [Assurance](./Debugging.md).
- To build an extension on-top of the AEP SDK, check out the [Building Extensions documentation](./EventHub/BuildingExtensions.md).
