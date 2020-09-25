# SystemInfoService

## Overview

The `SystemInfoService` lets you access critical pieces of information related to the user's device, such as carrier name, device name, locale, and more. The `SystemInfoService` can be accessed directly from the `ServiceProvider`.

## Declaration

##### `public protocol SystemInfoService`

## Usage

The following code snippet shows how to read the `SystemInfoService` and how to invoke the API to retrieve the user's active locale.

```swift
// Add a computed variable to your type or use it direclty in the function where required
private var systemInfoService: SystemInfoService {
  return ServiceProvider.shared.systemInfoService
}

// ...
let locale = systemInfoService.getActiveLocaleName()
```

## APIs

For a full list of APIs provided by the `SystemInfoService` see [`SystemInfoService.swift`](https://github.com/adobe/aepsdk-core-ios/blob/main/AEPServices/Sources/SystemInfoService.swift).
