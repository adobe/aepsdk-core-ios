# Implementation Validation with Assurance

The AEP SDK offers an extension to quickly inspect, validate, debug data collection, and experiences for any mobile app using the AEP SDK. We built Assurance to do the heavy lifting of getting an SDK implementation right, so app developers can focus on creating engaging experiences.

## Quick Setup

#### Install Compatibility Layer

The Assurance extension requires the backward-compatible layer. Instructions on installing the backward compatible layer can be found [here](./Migration/Migration_Install.md).

#### Add Assurance to your app

Include the Assurance extension via Cocoapods.

```ruby
pod 'AEPAssurance'
```

#### Update Extension Registration

Now that the backward compatible layer is installed, `ACPCore` can now be imported into the `AppDelegate` file allowing Assurance to be registered. Replace usage of `MobileCore.registerExtensions` with `ACPCore.registerExtensions` while including the Assurance extension.

```diff
+ import ACPCore
+ import AEPAssurance

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

+  AEPAssurance.registerExtension()  
+  ACPCore.registerExtensions([Lifecycle.self, Identity.self, Signal.self, ...], {
+     //...
+  })
-  MobileCore.registerExtensions([Lifecycle.self, Identity.self, Signal.self, ...], {
-      //...
-  })

  return true
} 
```

#### Next steps

Now that Assurance is installed and registered with Core, there are just a few more steps required.

- Assurance implementation instructions can be found [here](https://aep-sdks.gitbook.io/docs/beta/project-griffon/set-up-project-griffon#implement-project-griffon-session-start-apis-ios).
- Steps on how to use Assurance to validate SDK implementation can be found [here](https://aep-sdks.gitbook.io/docs/beta/project-griffon/using-project-griffon).
