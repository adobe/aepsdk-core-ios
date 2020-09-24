# DataQueuing

## Overview

`DataQueuing` is a service that provides access to FIFO queues. This service is particularly useful when used in conjunction with a `PersistentHitQueue`.

## Declaration

##### `@objc(AEPDataQueuing) public protocol DataQueuing`

## Usage

The following code snippet shows how to create a `DataQueue` and add a `DataEntity` to the queue.

```swift
// Create a `DataQueue`
guard let dataQueue = ServiceProvider.shared.dataQueueService.getDataQueue(label: name) else {
  Log.error(label: "\(name):\(#function)", "Failed to create Data Queue")
  return
}

// Create a `DataEntity`
let entity = DataEntity(data: myData)

// Add entity to `dataQueue`
dataQueue.add(entity)
```

## APIs

For a full list of APIs provided by the `DataQueuing` service, see [`DataQueuing.swift`](https://github.com/adobe/aepsdk-core-ios/blob/main/AEPServices/Sources/dataqueue/DataQueuing.swift).

## Further Reading

Additional types such as [`DataQueue`](https://github.com/adobe/aepsdk-core-ios/blob/main/AEPServices/Sources/dataqueue/DataQueue.swift), [`DataEntity`](https://github.com/adobe/aepsdk-core-ios/blob/main/AEPServices/Sources/dataqueue/DataEntity.swift), and [`PersistentHitQueue`](https://github.com/adobe/aepsdk-core-ios/blob/main/AEPServices/Sources/utility/hitprocessor/PersistentHitQueue.swift) are useful when using the`DataQueuing` service.
