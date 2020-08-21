# AEP SDK Swift Style Guide

Read [Apple's API design guidelines](https://swift.org/documentation/api-design-guidelines/) for a complete style guide.

This style guide highlights common patterns from the above linked style guide, while also addressing things unique to the AEP SDK.

## Table of Contents:

- [Structs vs. Classes](#structs-vs-classes)
- [Naming](#naming)
  - [Classes, Structs, Protocols, Enums, and Extensions](#classes-structs-protocols-enums-and-extensions)
  - [Variables](#variables)
  - [AEP Extensions](#aep-extensions)
  - [AEP 'Services'](#aep-services)
- [General](#general)
  - [Use of `self`](#use-of-self)
  - [Extensions](#extensions)
  - [Attributes](#attributes)
  - [Type Inference](#type-inference)
  - [Shortcut Declarations](#shortcut-declarations)
  - [Optional Binding](#optional-binding)
  - [Data Store Keys](#data-store-keys)
- [Documentation Guidelines](#documentation-guidelines)


## Structs vs. Classes

Apple recommends the use of Structs by default. Use classes when you need Swift Class features such as polymorphism, Objective-C interoperability, or reference type features. Note that rather than using polymorphism by default, make use of Swift's protocols over inheritance when possible.

## Naming

### Classes, Structs, Protocols, Enums, and Extensions

#### Classes

#### Structs

#### Protocols

Protocols that describe what something is should read as nouns (e.g. `Collection`).

Protocols that describe a capability should be named using the suffixes "able", "ible", or "ing" (e.g. `Equatable`, `ProgressReporting`).

### Variables

#### Constants

Use caseless enums to store constants as static variables. NOTE: The advantage of using enums over structs is that they can't be mistakenly instantiated and function as a pure namespace.

Preferred:
```swift
enum LifecycleConstants {
  static let start = "start"
  static let pause = "pause"
}
```

Not Preferred:
```swift
extension AEPCore: Lifecycle {
  // Constants
  static let start = "start"
  static let pause = "pause"

}
```

### AEP Extensions

* The module name of AEP extension should be prefixed with `AEP`.

  Preferred:
  ```
  AEPCore
  AEPLifecycle
  ```

* The class name of AEP extension should NOT use prefix `AEP`.

  Preferred:
  ```
  MobileCore.swift
  Lifecycle.swift
  ```
* The class defining `MobileCore` public API for each Core extension should be named “MobileCore” and the extension's name separated by a “+”.

  Preferred:
  ```
  MobileCore+Lifecycle.swift
  ```
  Not Preferred:
  ```
  MobileCoreLifecycle.swift
  ```

### AEP Services

* The name of the services protocol should end with `-ing` or any other suffix recommanded by [Apple's API design guidelines](https://swift.org/documentation/api-design-guidelines/).

* The implemetation classes of the services should be prefixed by a name which indicates the service being provided, followed by `Service`.

  Protocol:
  ```
  Networking.swfit
  ```
  Implementation:
  ```
  NetworkService.swift
  ```

## General

### Use of Self

Avoid using `self` since Swift does not require it to access an object’s properties or invoke its methods. Use self only when required by the compiler (in @escaping closures, or in initializers to disambiguate properties from arguments).

### Extensions

Avoid defining public extensions on a class/struct/protocol you don't own, otherwise it may lead to name conflict if the app or another 3rd party lib the app depends on also extends a same method. But you can define internal or private extensions on any type.

### Attributes

We will be implementing a linter to help maintain style for attributes. You can find the definition here: https://realm.github.io/SwiftLint/attributes.html

##### Attributes should be on their own lines in functions and types.

This includes but is not limited to:

- classes
- protocols
- structs
- extensions
- enums
- methods

Example:
```swift
@objc(AEPMyClass)
class MyClass {

}

@discardableResult
func canHazCheezburger() -> Bool {

}
```

##### Attributes should be on the same line as variables and imports.

Example:
```swift
@testable import MyTestLib

@nonobjc var onlyForSwift: String
```

### Type Inference

Use compiler provided type inference features to write shorter and cleaner code.

Preferred:
```swift
let str = "str"
```
Not Preferred:
```
let str: String = "str"
```

### Shortcut Declarations

Use shortcut type declarations over the full generic counterpart.

Preferred:
```swift
func getArray() -> [String]
func getDict() -> [String: String]
```
Not Preferred:
```swift
func getArray() -> Array<String>
func getDict() -> Dictionary<String, String>
```

### Optional Binding
For optional binding, shadow the original name when possible.

Preferred:
```swift
if let event = event { … }
```
Not Preferred:
```swift
if let unwrappedEvent = event { ... }
```

### Data Store Keys

Keys used to store values within `UserDefaults` or any other local storage should be of the following pattern:

- The constant definition should be in all uppercase 
- String value for the key should be all lowercase seperated by periods
- Be defined within an `enum` named `DataStoreKeys`

Preferred:

```swift
enum DataStoreKeys {
    static let IDENTITY_PROPERTIES = "identity.properties"
    static let PUSH_ENABLED = "push.enabled"
    static let ANALYTICS_PUSH_SYNC = "analytics.push.sync"
}
```

Not Preferred:

```swift
struct Keys {
    static let identityProperties = "identityProperties"
    static let PUSH_ENABLED = "pushEnabled"
    static let ANALYTICS_PUSH_SYNC = "analytics_push_sync"
}
```

## Documentation Guidelines

Use Apple's recommended [Markup language](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_markup_formatting_ref/AddingMarkup.html#//apple_ref/doc/uid/TP40016497-CH100-SW1) for documentation.

Preferred:
```swift
/**
 Creates a full name string from a given first name and last name

 - Parameters
    - firstName: The first name as a string
    - lastName: The last name as a string

 - Returns: The full name as a string
 */
func getFullName(firstName: String, lastName: String) -> String
```

Not Preferred:
```swift
// Returns a full name string from a given first name and last name
func getFullName(firstName: String, lastName: String) -> String
```
