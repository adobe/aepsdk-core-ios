# NamedCollectionProcessing

## Overview

The `NamedCollectionProcessing` service provides shared functionality to read and write values to local storage.

## Declaration

##### `public protocol NamedCollectionProcessing`

## Usage

While you can access the logging service directly via the `ServiceProvider`, it is recommended to use the wrapper class, `NamedCollectionDataStore`. This class can read and write values to local storage while using the underlying `NamedCollectionProcessing` service.

```swift
// Create your datastore
let dataStore = NamedCollectionDataStore(name: IdentityConstants.DATASTORE_NAME)

// Write values to local storage
dataStore.set(key: KEYS.LAUNCHES_SINCE_UPGRADE, value: 0)

// Read values from local storage
dataStore.getInt(key: KEYS.LAUNCHES_SINCE_UPGRADE)

// Remove values from local storage
dataStore.remove(key: KEYS.LAUNCHES_SINCE_UPGRADE)
```

## APIs

For a full list of APIs provided by the `NamedCollectionProcessing` service see [NamedCollectionProcessing.swift](https://github.com/adobe/aepsdk-core-ios/blob/main/AEPServices/Sources/storage/NamedCollectionProcessing.swift) and for a full list of APIs provided by the wrapper class see [NamedCollectionDataStore.swift](https://github.com/adobe/aepsdk-core-ios/blob/main/AEPServices/Sources/storage/NamedCollectionDataStore.swift).
