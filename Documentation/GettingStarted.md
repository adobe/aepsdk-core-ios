# Getting Started

## Set up a Mobile Property

Set up a mobile property as outlined in the Adobe Experience Platform [docs](https://aep-sdks.gitbook.io/docs/getting-started/create-a-mobile-property)

## Get the Swift Mobile Core

To install the Swift AEP Mobile Core, refer to this [document](https://github.com/adobe/aepsdk-core-ios#installation)

## Initial SDK Setup

Now that you have set up a mobile property and have installed the SDK, you are ready to begin integrating your application with the SDK.
1. Import each of the core extensions in your `AppDelegate` file:

```
import AEPCore
import AEPLifecycle
import AEPIdentity
import AEPSignal
```

2. Register the core extensions, configure the core with your assigned application identifier, and start lifecycle metrics.
To do this, you add the following code to your Application Delegate's `application(_:didFinishLaunchingWithOptions:)` method:

```
        MobileCore.registerExtensions([Lifecycle.self, Identity.self, Signal.self], {

            // Use the App id assigned to this application via Adobe Launch
            MobileCore.configureWith(appId: "yourAppID")
            if application.applicationState != .background {
                // only start lifecycle if the application is not in the background
                MobileCore.lifecycleStart(additionalContextData: ["contextDataKey": "contextDataVal"])
            }
        })
```


