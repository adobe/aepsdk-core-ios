# URLOpening

## Overview

The `URLOpening` service provides shared functionality for opening URLs. Overriding this service can be helpful to determine when the SDK will attempt to open a given URL.

## Declaration

##### `public protocol URLOpening`

## Usage

The following code snippet shows how to read the `URLOpening` service and open a given URL.

```swift
// Add a computed variable to your type or use it direclty in the function where required
private var urlService: URLOpening {
  return ServiceProvider.shared.urlService
}

// ...
urlService.openUrl(url)
```

## APIs

For a full list of APIs provided by the `URLOpening` see [`URLOpening.swift`](https://github.com/adobe/aepsdk-core-ios/blob/main/AEPServices/Sources/URLOpening.swift).
