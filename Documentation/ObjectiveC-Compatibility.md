# Objective-C Compatibility

When designing interfaces that can be used publicly, we should usually always make them compatible with Objective-C. This document covers some best practices to ensure that the code you write will be compatible with Objective-C.

## `@objc`

Nothing that is Swift Specific is visible in Objective-C, this means Swift enums, structs, classes that do not inherit from `NSObject`, and extensions on protocols.

To expose something to Objective-C, you need to add the `@objc` annotation in front of the type. When adding `@objc` to your type, you may encounter compiler errors telling you that something you have represented in Swift cannot be expressed in Objective-C.

## `@nonobjc`

`@nonobjc` can be used when you want to explicitly state that you do not want to export a symbol to Objective-C. `@nonobjc` can be useful when you have an Objective-C method that overrides a Swift method. This annotation is typically used rarely.

## Public APIs

All public APIs need to be compatible with Objective-C. This means they must use types that can be represented in Objective-C, which means types such as structs, enums with associated values cannot be used in public APIs.

To define a public API as being exposed in Objective-C you need to annotate the API with `@objc`. In the following example 

```swift
@objc(setPrivacy:)
static func setPrivacy(status: PrivacyStatus) {
    // ...
}
```

Then the API can be invoked in Objective-C with:

```objective-c
[AEPCore setPrivacy:PrivacyStatusOptedIn];
```

A slightly more complex example on a public API which takes multiple parameters:

```swift
@objc(syncIdentifiers:authenticationState:)
static func syncIdentifiers(identifiers: [String : String]?, authenticationState: MobileVisitorAuthenticationState) {
	// ...
}
```

Then it can be invoked in Objective-C with:

```objective-c
[AEPIdentity syncIdentifiers:@{@"type": @"id"} authenticationState:MobileVisitorAuthenticationStateLoggedOut];
```

## Make Extensions visible to Objective-C

Making your extension compatible with Objective-C is simple; you need to make your extension visible to Objective-C with the `@objc` annotation and ensure that your extension inherits from `NSObject`.

Example:

​	`@objc(AEPIdentity) public class Identity: NSObject, Extension {}`

> Note: In the above example, we rename the Swift class `Identity` to `AEPIdentity` to follow the 3-letter prefix for Objective-C.

Then you must ensure you invoke `super.init()` in your required initializer after all your properties have been initialized.

``` objective-c
public required init(runtime: ExtensionRuntime) {
    self.runtime = runtime
    super.init()
}
```
