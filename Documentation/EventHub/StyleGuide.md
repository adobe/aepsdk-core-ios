# AEP SDK Swift Style Guide
This style guide is meant to address things unique to the AEP SDK. Read [Apple's API design guidelines](https://swift.org/documentation/api-design-guidelines/) for a more complete style guide.

## Naming:
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
### Services
* Services should be prefixed by a name which indicates the service being provided, followed by `Service`. 

  Preferred:
  ```
  SystemInfoService
  ```
  Not Preferred:
  ```
  SystemInfo
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

## Use of Self:
Avoid using `self` since Swift does not require it to access an object’s properties or invoke its methods. Use self only when required by the compiler (in @escaping closures, or in initializers to disambiguate properties from arguments).

## Type Inference:
Use compiler provided type inference features to write shorter and cleaner code. 

Preferred:
```
let str = "str"
```
Not Preferred:
```
let str: String = "str"
```

## Shortcut Declarations
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

## Constants
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

## Structs Vs. Classes
Apple recommends the use of Structs by default. Use classes when you need Swift Class features such as polymorphism, Objective-C interoperability, or reference type features. Note that rather than using polymorphism by default, make use of Swift's protocols over inheritance when possible. 
