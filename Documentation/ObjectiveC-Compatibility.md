# Objective-C Compatibility

When designing interfaces that can be used publicly, the interfaces should always be compatible with Objective-C. This document covers some best practices to ensure that the code written will be compatible with Objective-C.

## [Annotate with Attributes](https://docs.swift.org/swift-book/ReferenceManual/Attributes.html)

### `@objc`

To expose something to Objective-C, add the `@objc` attribute in front of it. If a compiler error is present, it may indicate that the represented Swift type cannot be expressed in Objective-C.

Nothing that is Swift-specific is representable in Objective-C. This list includes:
- Swift enums
- structs
- classes that do not inherit from `NSObject`
- extensions on protocols

### `@nonobjc`

`@nonobjc` can be used to explicitly state that a symbol should not be exported to Objective-C. `@nonobjc` can be useful in the scenario where an Objective-C method overrides a Swift method. This attribute is rarely used.

## Public APIs

All public APIs need to be compatible with Objective-C. Public APIs must use types representable in Objective-C. See the list above for Swift-specific types.

To define a public API as being exposed in Objective-C you need to annotate the API with the `@objc` attribute.

For example:

```swift
@objc(setPrivacy:)
static func setPrivacy(status: PrivacyStatus) {
    // ...
}
```

The `@objc(setPrivacy:)` annotation exposes this API to Objective-C. It can be invoked as follows:

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

## Make AEP SDK Extensions visible to Objective-C

To make an extension compatible with Objective-C, use the `@objc` attribute and ensure that the extension inherits from `NSObject`.

Example:

```swift
@objc(AEPMobileIdentity)
public class Identity: NSObject, Extension {
    ...
}
```

> Note: In the above example, the Swift class is named `Identity` but renamed to `AEPMobileIdentity` following the 3-letter prefix for Objective-C. Keep in mind that types cannot share names with their containing framework, due to Swift limitations.

Calling `super.init()` in the required initializer should happen after all class properties have been initialized.

```swift
public required init(runtime: ExtensionRuntime) {
    self.runtime = runtime
    super.init()
}
```
