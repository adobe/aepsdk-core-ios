# AEP SDK Swift Style Guide

Read [Apple's API design guidelines](https://swift.org/documentation/api-design-guidelines/) for a complete style guide.

This style guide highlights common patterns from the above linked style guide, while also addressing things unique to the AEP SDK.

## Table of Contents:

- [Structs vs. Classes](#structs-vs-classes)
- [Naming](#naming)
  - [Protocols](#protocols)
  - [Variables](#variables)
  - [Methods](#methods)
  - [AEP Extensions](#aep-extensions)
  - [AEP Services](#aep-services)
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

#### Protocols

Protocols that describe what something is should read as nouns (e.g. `Collection`).

Protocols that describe a capability should be named using the suffixes "able", "ible", or "ing" (e.g. `Equatable`, `ProgressReporting`).

See [Apple's API design guidelines](https://swift.org/documentation/api-design-guidelines/) for details.

#### Variables

Prefer "camelCase" patterns when naming variables.

#### Methods

Always name parameters for a method. If the method name ends with a word that makes the name of the first parameter implicit, make the parameter name optional.

*Examples:*
```swift
func receiveConfigurationRequest(event: Event)

func readyForEvent(_ event: Event) -> Bool
```

If your method has a trailing closure parameter, name it `completion:`.

*Example:*
```swift
func processHit(entity: DataEntity, completion: @escaping (Bool) -> Void) 
```

#### Constants

Prefer using case-less `enums` to store constants as static variables.

*Example:*
```swift
enum LifecycleConstants {
  static let START = "START"
  static let PAUSE = "PAUSE"
}
```

> Note: The advantage of using `enums` over `structs` is that they function as a pure namespace and cannot be mistakenly instantiated.

When defining a constant outside of an `enum`, they should be defined as `private` and can either be `static` or just an instance variable depending on the use case. Prefer using upper-case with underscores between words.

*Example:*
```swift
class Lifecycle {
  private static let START = "START"
  private static let PAUSE = "PAUSE"
  private let MY_CONST = "MY_CONST"
}
```

*Not Preferred:*
```swift
class Lifecycle {
  static let start = "start"
  let pause = "pause"
  let MY_CONST = "MY_CONST"
}
```

### AEP Extensions

* The module name of an AEP extension should be prefixed with "AEP".

  *Example:*
  ```
  AEPCore
  AEPLifecycle
  ```

* The Swift class name of an AEP extension should NOT use prefix "AEP".

  *Example:*
  ```
  MobileCore.swift
  Lifecycle.swift
  ```

* The Objective-C class name of AEP extension should use the prefix "AEPMobile".

  *Example:*
  ```
  @objc(AEPMobileCore)
  public class MobileCore: NSObject, Extension {
      ...
  }

  @objc(AEPMobileLifecycle)
  public class Lifecycle: NSObject, Extension {
      ...
  }
  ```

* Each module should define a class extension on `MobileCore` that defines its public API. The name should be "MobileCore" and the extension's name, separated by a "+" character.

  *Example:*
  ```
  MobileCore+Lifecycle.swift
  ```

### AEP Services

* Name the services protocol according to the [`protocol`](#protocol) naming recommendation.

* Classes that implement a service protocol should be prefixed with a name that indicates the service being provided, followed by "Service".

  *Example:*  
  ```
  // protocol name
  Networking.swift

  // implementing class name
  NetworkService.swift
  ```

## General

### Use of Self

Avoid using `self` since Swift does not require it to access an object’s properties or invoke its methods. Use `self` only when required by the compiler (in `@escaping` closures, or in initializers to disambiguate properties from arguments).

### Extensions

Avoid defining public extensions on a `class`/`struct`/`protocol` you don't own. Doing so may lead to name conflict if the app or another 3rd party library the app depends on that also extends the same method. Otherwise, defining `internal` or `private` extensions on any type is acceptable.

### Attributes

The project uses a linter to help maintain style for attributes. Definitions of the linter rules for attributes can be found here: https://realm.github.io/SwiftLint/attributes.html

##### Attributes should be on their own lines in functions and types.

This includes but is not limited to:

- classes
- protocols
- structs
- extensions
- enums
- methods

*Example:*
```swift
@objc(AEPMyClass)
class MyClass {
    ...
}

@discardableResult
func addToQueue(_ item: String) -> Bool {
    ...
}
```

##### Attributes should be on the same line as variables and imports.

*Example:*
```swift
@testable import MyTestLib

@nonobjc var onlyForSwift: String
```

### Type Inference

Use compiler provided type inference features to write shorter and cleaner code.

*Example:*
```swift
let str = "str"
```

*Not Preferred:*
```
let str: String = "str"
```

### Shortcut Declarations

Use shortcut type declarations over the full generic counterpart.

*Example:*
```swift
func getArray() -> [String]
func getDict() -> [String: String]
```

*Not Preferred:*
```swift
func getArray() -> Array<String>
func getDict() -> Dictionary<String, String>
```

### Optional Binding
For optional binding, shadow the original name when possible.

*Example:*
```swift
if let event = event { … }
```

*Not Preferred:*
```swift
if let unwrappedEvent = event { ... }
```

### Data Store Keys

Key and values stored within `UserDefaults` or any other local storage should follow these rules:

- The constant variable name should be in all uppercase
- A `String` value should be all lowercase, separated by periods
- Keys and values should be defined within an `enum` named "DataStoreKeys"

*Example:*
```swift
enum DataStoreKeys {
    static let IDENTITY_PROPERTIES = "identity.properties"
    static let PUSH_ENABLED = "push.enabled"
    static let ANALYTICS_PUSH_SYNC = "analytics.push.sync"
}
```

*Not Preferred:*

```swift
struct Keys {
    static let identityProperties = "identity.Properties"
    static let PUSH_ENABLED = "pushEnabled"
    static let ANALYTICS_PUSH_SYNC = "analytics_push_sync"
}
```

## Documentation Guidelines

Use Apple's recommended [Markup language](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_markup_formatting_ref/AddingMarkup.html#//apple_ref/doc/uid/TP40016497-CH100-SW1) for in-code documentation.

*Example:*
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
