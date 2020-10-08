# Third-party Extension Support for Customers

All existing third-party extensions are compatible with the AEP Swift SDK. Using third-party extensions will need to use the backward compatibility layer and update how extensions are registered. This document will walk through the steps to get setup using third-party extensions in the AEP Swift SDK.

## Quick Setup

#### Install Compatibility Layer

Existing third-party extensions require the backward compatibility layer. Instructions on installing the backwards compatibility layer can be found [here](./Migration/ACP-Migration.md).

#### Update Extension Registration

Now that the backwards compatibility layer is installed, `ACPCore` can be imported into the `AppDelegate` file allowing third-party extensions to be registered. Replace usage of `MobileCore.registerExtensions` with `ACPCore.registerExtensions` while including the additional third-party extensions.

```diff
+ import ACPCore
+ import ThirdPartyExtension

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

+  // Register any third-party extensions before `registerExtensions`
+  ThirdPartyExtension.registerExtension()
+  ACPCore.registerExtensions([Lifecycle.self, Identity.self, Signal.self, ...], {
+     //...
+  })
-  MobileCore.registerExtensions([Lifecycle.self, Identity.self, Signal.self, ...], {
-     //...
-  })

 return true
} 
```
