# Getting Started

This guide will walk you through how to get up and running with the AEP Swift SDK with only a few lines of code.

> If you are an existing ACP SDK customer, check out the [migration document](./Migration/ACP-Migration.md).

## Set up a Mobile Property

Set up a mobile property as outlined in the Adobe Experience Platform [docs](https://aep-sdks.gitbook.io/docs/getting-started/create-a-mobile-property)

## Get the Swift Mobile Core

To install the Swift AEP Mobile Core, refer to this [document](https://github.com/adobe/aepsdk-core-ios#installation)

## Initial SDK Setup

Now that you have set up a mobile property and have installed the SDK, you are ready to begin integrating your application with the SDK.
1. Import each of the core extensions in your `AppDelegate` file:

```swift
import AEPCore
import AEPLifecycle
import AEPIdentity
import AEPSignal
```

2. Register the core extensions, configure the core with your assigned application identifier, and start lifecycle metrics.
To do this, you add the following code to your Application Delegate's `application(_:didFinishLaunchingWithOptions:)` method:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

  // Enable debug logging
  MobileCore.setLogLevel(level: .trace)

  MobileCore.registerExtensions([Lifecycle.self, Identity.self, Signal.self], {
    // Use the App id assigned to this application via Adobe Launch
    MobileCore.configureWith(appId: "yourAppId")
    if application.applicationState != .background {
      // Only start lifecycle if the application is not in the background
      MobileCore.lifecycleStart(additionalContextData: ["contextDataKey": "contextDataVal"])
    }
     
  })  
  return true
}
```

## Implement Lifecycle Metrics

Lifecycle metrics is an optional, yet valuable feature provided by the Adobe Experience Platform SDK. It provides out-of-the-box, application lifecycle information about your app user. These metrics contain information on the app user's engagement lifecycle such as device information, install or upgrade information, session start and pause times, etc. You can also set additional lifecycle metrics.



Start Lifecycle data collection by calling `lifecycleStart:` from within the callback of `AEPCore.registerExtensions:`.

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

  // Enable debug logging
  MobileCore.setLogLevel(level: .trace)

  MobileCore.registerExtensions([Lifecycle.self, Identity.self, Signal.self], {
    // Use the App id assigned to this application via Adobe Launch
    MobileCore.configureWith(appId: "yourAppId")
    if application.applicationState != .background {
      // Only start lifecycle if the application is not in the background
      MobileCore.lifecycleStart(additionalContextData: ["contextDataKey": "contextDataVal"])
    }
     
  })  
  return true
}
```

When launched, if your app is resuming from a backgrounded state, iOS might call your `applicationWillEnterForeground:` delegate method. You also need to call `lifecycleStart:`, but this time you do not need all of the supporting code that you used in `application:didFinishLaunchingWithOptions:`:

```swift
func applicationWillEnterForeground(_ application: UIApplication) {   
  AEPCore.lifecycleStart(nil)
}
```

When the app enters the background, pause Lifecycle data collection from your app's `applicationDidEnterBackground:` delegate method:

```swift
func applicationDidEnterBackground(_ application: UIApplication) {   
  AEPCore.lifecyclePause()
}
```

## Sample Apps

To download more examples of integrating the AEP Swift SDK, head over to our sample app resources.

[View Samples](https://github.com/adobe/aepsdk-sample-app-ios)

## Next Steps

- Get familiar with the various APIs offered by the AEP SDK by checking out our [API usage documents](./Usage/). 
- If you want to leverage shared services offered by the AEP SDK, check out the [Services documentation](./Services/README.md).
- If you want to build an extension on-top of the AEP SDK, check out the [Building Extensions documentation](./EventHub/BuildingExtensions.md).

