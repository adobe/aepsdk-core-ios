# Event Hub Events

This document outlines the specification for an Event Hub `Event`. These events are dispatched from the Event Hub and received by listeners that are registered with the Event Hub.

### Event Specification

| Name       | Type           | Description                                                  |
| ---------- | -------------- | ------------------------------------------------------------ |
| name       | String         | Event name used primarily for logging                        |
| id         | UUID           | UUID which uniquely identifies this event                    |
| type       | String         | See [Event Type](#event-type)                                |
| source     | String         | See [Event Source](#event-source)                            |
| data       | [String: Any]? | Dictionary holding one or more key value pairs that are associated with the event. |
| timestamp  | Date           | The time that this event was generated                       |
| responseID | UUID?          | If this event was generated in response to a previous event, this value holds the `id` of the triggering event. |
| mask       | [String]       | Specifies the properties in the Event and its data that should be used in the hash for `EventHistory` storage. |  

### Event Type

Every `Event` has an `EventType` enum associated with it, which defines what kind of event it is and determines who is notified when this event occurs.

For a full list of possible event types, see [EventType.swift](https://github.com/adobe/aepsdk-core-ios/blob/main/AEPCore/Sources/eventhub/EventType.swift).

### Event Source

Along with an `EventType`, an `Event` has a `EventSource` enum associated with it, which defines where the event originated and is used to determine who is notified when this event occurs.

For a full list of possible event sources, see [EventSource.swift](https://github.com/adobe/aepsdk-core-ios/blob/main/AEPCore/Sources/eventhub/EventSource.swift).

### Creating an `Event`

Creating a new `Event` is easy:

```swift
let event = Event(name: "MyEvent", type: EventType.analytics, source: EventSource.responseContent, data: ["myKey": true])
```
