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
  - [Type Inference](#type-inference)
  - [Shortcut Declarations](#shortcut-declarations)
  - [Optional Binding](#optional-binding)
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
```
enum LifecycleConstants {
  static let start = "start"
  static let pause = "pause"
}
```

Not Preferred:
```
extension AEPCore: Lifecycle {
  // Constants
  static let start = "start"
  static let pause = "pause"

}
```

### AEP Extensions

* The files for the AEP extension should be prefixed with `AEP` followed by the extension name.

  Preferred:
  ```
  AEPLifecycle.swift
  ```
  Not Preferred:
  ```
  Lifecycle.swift
  ```
* The `AEPCore` extension for a given AEP extension should be named “AEPCore” and the extension's name separated by a “+”.

  Preferred:
  ```
  AEPCore+Lifecycle.swift
  ```
  Not Preferred:
  ```
  AEPCoreLifecycle.swift
  ```

### AEP Services

* Services should be prefixed by a name which indicates the service being provided, followed by `Service`.

  Preferred:
  ```
  SystemInfoService
  ```
  Not Preferred:
  ```
  SystemInfo
  ```

## General

### Use of Self

Avoid using `self` since Swift does not require it to access an object’s properties or invoke its methods. Use self only when required by the compiler (in @escaping closures, or in initializers to disambiguate properties from arguments).

### Extensions

Avoid defining public extensions on a class/struct/protocol you don't own, otherwise it may lead to name conflict if the app or another 3rd party lib the app depends on also extends a same method. But you can define internal or private extensions on any type.

### Type Inference

Use compiler provided type inference features to write shorter and cleaner code.

Preferred:
```
let str = "str"
```
Not Preferred:
```
let str: String = "str"
```

### Shortcut Declarations

Use shortcut type declarations over the full generic counterpart.

Preferred:
```
func getArray() -> [String]
func getDict() -> [String: String]
```
Not Preferred:
```
func getArray() -> Array<String>
func getDict() -> Dictionary<String, String>
```

### Optional Binding
For optional binding, shadow the original name when possible.

Preferred:
```
if let event = event { … }
```
Not Preferred:
```
if let unwrappedEvent = event { ... }
```

## Documentation Guidelines

Use Apple's recommended [Markup language](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_markup_formatting_ref/AddingMarkup.html#//apple_ref/doc/uid/TP40016497-CH100-SW1) for documentation.

Preferred:
```
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
```
// Returns a full name string from a given first name and last name
func getFullName(firstName: String, lastName: String) -> String
```
