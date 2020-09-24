# Logging

## Overview

The `Logging` service provides shared functionality to write messages to the console.

## Declaration

##### `public protocol Logging`

## Usage

While you can access the `Logging` service directly via the `ServiceProvider`, it is recommended to use the wrapper class, `Log`. This class can be used to read and write messages to the console.

```swift
// Log a message using the wrapper `Log` class
Log.debug(label: "label", "My log message")
```

## APIs

For a full list of APIs provided by the `Logging` service, see [Logging.swift](https://github.com/adobe/aepsdk-core-ios/blob/main/AEPServices/Sources/log/Logging.swift) and for a complete list of APIs provided by the wrapper class, see [Log.swift](https://github.com/adobe/aepsdk-core-ios/blob/main/AEPServices/Sources/log/Log.swift).
