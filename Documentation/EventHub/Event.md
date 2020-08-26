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

### Event Type

Every `Event` has an `EventType` enum associated with it, which defines what kind of event it is and determines who is notified when this event occurs.

| Name              | Case             | Raw Value                             |
| ----------------- | ---------------- | ------------------------------------- |
| Acquisition       | acquisition      | com.adobe.eventType.acquisition       |
| Analytics         | analytics        | com.adobe.eventType.analytics         |
| Audience Manager  | audienceManager  | com.adobe.eventType.audienceManager   |
| Campaign          | campaign         | com.adobe.eventType.campaign          |
| Configuration     | configuration    | com.adobe.eventType.configuration     |
| Custom            | custom           | com.adobe.eventType.custom            |
| Hub               | hub              | com.adobe.eventType.hub               |
| Identity          | identity         | com.adobe.eventType.identity          |
| Lifecycle         | lifecycle        | com.adobe.eventType.lifecycle         |
| Location          | location         | com.adobe.eventType.location          |
| PII               | pii              | com.adobe.eventType.pii               |
| Rules Engine      | rulesEngine      | com.adobe.eventType.rulesEngine       |
| Signal            | signal           | com.adobe.eventType.signal            |
| System            | system           | com.adobe.eventType.system            |
| Target            | target           | com.adobe.eventType.target            |
| User Profile      | userProfile      | com.adobe.eventType.userProfile       |
| Places            | places           | com.adobe.eventType.places            |
| Generic Track     | genericTrack     | com.adobe.eventType.generic.track     |
| Generic Lifecycle | genericLifecycle | com.adobe.eventType.generic.lifecycle |
| Generic Identity  | genericIdentity  | com.adobe.eventType.generic.identity  |
| Generic Pii       | genericPii       | com.adobe.eventType.generic.pii       |
| Generic Data      | genericData      | com.adobe.eventType.generic.data      |
| Wildcard          | wildcard         | com.adobe.eventType.\_wildcard_       |

### Event Source

Along with an `EventType`, an `Event` has a `EventSource` enum associated with it, which defines where the event originated and is used to determine who is notified when this event occurs.

| Name              | Case             | Raw Value                              |
| ----------------- | ---------------- | -------------------------------------- |
| Booted            | booted           | com.adobe.eventSource.booted           |
| None              | none             | com.adobe.eventSource.none             |
| OS                | os               | com.adobe.eventSource.os               |
| Request Content   | requestContent   | com.adobe.eventSource.requestContent   |
| Request Identity  | requestIdentity  | com.adobe.eventSource.requestIdentity  |
| Request Profile   | requestProfile   | com.adobe.eventSource.requestProfile   |
| Request Reset     | requestReset     | com.adobe.eventSource.requestReset     |
| Response Content  | responseContent  | com.adobe.eventSource.responseContent  |
| Response Identity | responseIdentity | com.adobe.eventSource.responseIdentity |
| Response Profile  | responseProfile  | com.adobe.eventSource.responseProfile  |
| Shared State      | sharedState      | com.adobe.eventSource.sharedState      |
| Wildcard          | wildcard         | com.adobe.eventSource.\_wildcard_      |

### Creating an `Event`

Creating a new `Event` is easy:

```swift
let event = Event(name: "MyEvent", type: EventType.analytics, source: EventSource.responseContent, data: ["myKey": true])
```
