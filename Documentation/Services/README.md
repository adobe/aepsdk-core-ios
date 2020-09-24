# Services

## Contents
- [Overview](#overview)
-  [`ServiceProvider`](#-serviceprovider-)
- [Implementing a Service](#implementing-a-service)
- [Overriding a Service](#overriding-a-service)
- [Provided Services](#provided-services)

## Overview

The AEP SDK contains a set of services. These services provide shared functionality throughout the SDK that can be shared by extensions. For example, services provide shared functionality for networking, logging, caching, and more.

A public protocol defines each service; this allows customers to override services if they see fit. For example, here is the definition of the `Logging` service responsible for supplying shared logging functionality to all extensions.

```swift
/// Represents the interface of the logging service
@objc(AEPLogging) public protocol Logging {
  /// Logs a message
  /// - Parameters:
  ///  - level: One of the message level identifiers, e.g., DEBUG
  ///  - label: Name of a label to localize message
  ///  - message: The string message
  func log(level: LogLevel, label: String, message: String)
}
```

The `Logging` service above defines a simple interface for logging messages.

## `ServiceProvider`

The SDK provides a shared `ServicesProvider`, responsible for maintaining the current set of provided services and any potential service overrides. 

It is essential always to use the `shared` property of the `ServiceProvider`, which is the singleton shared throughout the SDK.

## Accessing Services

Some services provide wrapper classes. For example, the `Log` class is a wrapper around the `LoggingService`. However, in some cases, a wrapper class may not exist, and one might need to access a service directly from the ServiceProvider. The recommended way to do this is through a computed variable or directly through the ServiceProvider when required. This ensures that if the service is overridden, the service consumer always uses the correct service implementation.

```swift
private var cacheService: Caching {
    return ServiceProvider.shared.cacheService
}
```

## Implementing a Service

This example will show how one would implement their own `Logging` service throughout the SDK.

First, one must implement a type that conforms to the `Logging` protocol, as defined above. We will do this by defining a logging service that only prints out messages with a log level of `Error`.

```swift
class ErrorLogger: Logging {
  func log(level: LogLevel, label: String, message: String) {
    guard level == .error else { return }
    print("\(label): \(message)")
  }
}
```

In the code snippet above, we have a class that implements `Logging` and provides simple implementation for the single required API.

## Overriding a Service

As we saw above, implementing the `Logging` protocol was quite simple, but how do we get the entire SDK to take advantage of this new service in place of the default implementation?

We can do this by setting the `loggingService` on the shared `ServiceProvider`, used by the entire SDK.

```swift
ServiceProvider.shared.loggingService = ErrorLogger()
```

If one wishes to revert to the `loggingService` default implementation, you can set the `loggingService` to nil.

```swift
ServiceProvider.shared.loggingService = nil
```

> Note: Use caution when overriding services. Changes to behavior for a given service can have unintended consequences throughout the SDK.

## Provided Services

- `SystemInfoService`
- `NamedCollectionProcessing`
- `Networking`
- `DataQueuing`
- `Caching`
- `URLOpening`
- `Logging`
