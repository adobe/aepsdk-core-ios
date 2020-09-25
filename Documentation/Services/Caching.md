# Caching

## Overview

`Caching` describes a service that temporarily holds data and supports read and write operations. The default implementation of the `Caching` is provided by the `DiskCacheService`, which cached items on the disk.

## Declaration

##### `public protocol Cache`

## Usage

While you can access the `Caching` service directly via the `ServiceProvider`, it is recommended to use the wrapper class, `Cache`. This class can read and write values to a cache while using the underlying `Caching` service.

```swift
// Create a cache
let cache = Cache(name: "a-cache")

// Create a `CacheEntry`
let cacheEntry = CacheEntry(data: data, expiry: .never, metadata: nil)

// Write the `CacheEntry` to `Cache`
try? cache.set(key: "cache-key", entry: cacheEntry)

// Read values from cache
let cachedEntry = cache.get(key: "cache-key")

// Remove values from cache
cache.remove(key: "cache-key")
```

## APIs

For a full list of APIs provided by the `Caching` service, see [Caching.swift](https://github.com/adobe/aepsdk-core-ios/blob/main/AEPServices/Sources/cache/Caching.swift) and for a full list of APIs provided by the wrapper class, see [Cache.swift](https://github.com/adobe/aepsdk-core-ios/blob/main/AEPServices/Sources/cache/Cache.swift).
