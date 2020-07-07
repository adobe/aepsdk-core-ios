# AEP SDK Swift Style Guide
This style guide is meant to address things unique to the AEP SDK. Read [Apple's API design guidelines](https://swift.org/documentation/api-design-guidelines/) for a more complete style guide.

## Naming:
### AEP extensions
* The files for the AEP extension should be prefixed with `AEP` followed by the extension name. E.g `AEPLifecycle.swift`. 
* The `AEPCore` extension for a given AEP extension should be named “AEPCore” and the extensions name separated by a “+”. E.g: `AEPCore+Lifecycle.swift`.
### Services
* Services should be prefixed by a name which indicates the service being provided, followed by `Service`. E.g: `SystemInfoService`
### Optional Binding
For optional binding, shadow the original name when possible. E.g: `if let event = event { … }`

## Use of Self:
Avoid using `self` since Swift does not require it to access an object’s properties or invoke its methods. Use self only when required by the compiler. 
