# Networking

## Overview

The `Networking` service provides shared functionality to make asynchronous network requests and handle their responses.

## Declaration

##### `public protocol Networking`

## Usage

The following code snippet details how to make a simple network request and handle the response.

```swift
// Create your `NetworkRequest`, for more details see `NetworkRequest.swift`
let networkRequest = NetworkRequest(url: url, httpMethod: .get, httpHeaders: headers)

// Get an instance of the current network service
let networkService = ServiceProvider.shared.networkService

// Make a request
networkService.connectAsync(networkRequest: networkRequest) { httpConnection in
  // handle `httpConnection`
}
```

## APIs

For a full list of APIs provided by the `Networking` service, see [Networking.swift](https://github.com/adobe/aepsdk-core-ios/blob/main/AEPServices/Sources/storage/Networking.swift).

## Further Reading

Additional types such as [`NetworkRequest`](https://github.com/adobe/aepsdk-core-ios/blob/main/AEPServices/Sources/network/NetworkRequest.swift) and [`HttpConnection`](https://github.com/adobe/aepsdk-core-ios/blob/main/AEPServices/Sources/network/HttpConnection.swift) are required to send and handle network requests.
