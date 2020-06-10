# Building Extensions

Extensions allow developers to extend the Experience Platform SDKs with their code. Building an extension includes listening for and dispatching events, reading the shared state of any registered extension, and sharing the state of the current extension. The application can use the extension to monitor for information that Adobe does not expose by default. It can also use the extension to modify Experience Platform SDK internal operations, for example, by adding additional data to messages that are sent or by sending data to other systems.

This document covers the high level concepts about developing your own extension.

#### Defining an Extension

For an extension to be registered with the `EventHub`, it must conform to the `Extension` protocol. The `Extension` protocol defines an `Extension` as a class which provides a parameterless initializer, a  `name`, `version` and implements two methods: `onRegistered()` and `onUnregistered()` .

See [`Extension.swift`](https://github.com/adobe/aepsdk-core-ios/blob/master/Sources/eventhub/Extension.swift) for the complete definition.

#### Events

##### Purpose of an `Event`

- Triggering actions in the Experience Platform SDKs. Events are used by the extensions to signal when specific actions should occur, for example, to send an Analytics hit. Extensions can send the same types of events that the Experience Platform SDKs would send internally to trigger these actions.
- Triggering actions in another extension. Some applications might have multiple extensions, and some of these extensions might have their events defined that trigger actions.

##### Creating an `Event`

```swift
let event = Event(name: "Configuration Request Event", type: .configuration, source: .requestContent, data: data)
```

##### Creating a response `Event`

```swift
let triggerEvent: Event = ...
let responseEvent = triggerEvent.createResponseEvent(name: "Configuration Response Event", type: .configuration, source: .responseContent, data: data)
```

#### Dispatching Events

Extensions can dispatch an `Event` to the `EventHub` via the `dispatch(event: Event)` API, which is provided by default to all classes that implement `Extension`. This API will result in all listeners whose `EventType` and `EventSource` match to be invoked with the `event`.

```swift
let event = Event(name: "My Event", type: .analytics, source: .requestContent, data: myData)
dispatch(event: event)
```

##### Dispatching response Events

Occasionally, an extension may want to dispatch a response event for a given `Event`, to do this an extension must first create the response `Event` from the trigger `Event`, then dispatch it through the `EventHub`, this will notify any response listeners registered for `triggerEvent`

```swift
let triggerEvent: Event = ...
let responseEvent = triggerEvent.createResponseEvent(name: "Configuration Response Event", type: .configuration, source: .responseContent, data: data)
dispatch(event: responseEvent)
```

#### Listening for Events

Extensions can listen for events that are dispatched through the `EventHub` with a listener. Listeners define which events they are interested in being notified about through an `EventType` and `EventSource`. A listener is a closure or function which takes in an `Event` as a parameter and does not return a value.

```swift
public typealias EventListener = (Event) -> ()
```

The `EventHub` provides extensions two APIs for listening for Events:

```swift
// Registers a `EventListener` with the `EventHub`
registerListener(type: EventType, source: EventSource, listener: @escaping EventListener)

// Registers an `EventListener` with the `EventHub` that is invoked when `triggerEvent`'s response event is dispatched
registerResponseListener(triggerEvent: Event, listener: @escaping EventListener)
```

> Note: Registering listeners should be done in the `onRegistered()` function of an extension.

##### Listener Example

```swift
// receiveConfigurationRequest is invoked whenever the `EventHub` dispatches an event with type configuration and source request content
registerListener(type: .configuration, source: .requestContent, listener: receiveConfigurationRequest(event:))

private func receiveConfigurationRequest(event: Event) {
   // handle event
}

// Can also be implemented with a closure
registerListener(type: .configuration, source: .requestContent) { (event) in
   // handle event            
}
```

##### Wildcard Listeners

Some extensions may have the requirement to be notified of all events that are dispatched from the `EventHub`, in this case, a `wildcard` `EventType` and `EventSource` are available.

```swift
// Invoked for all events that are dispatched from the `EventHub`
registerListener(type: .wildcard, source: .wildcard) { (event) in
   // handle event            
}
```

##### Response Listeners

Response listeners allow extensions to listen for the response event of a given trigger `Event`.

```swift
let triggerEvent = Event(name: "Trigger Event", type: .identity, source: .requestIdentity, data: nil)

registerResponseListener(triggerEvent: triggerEvent) { (responseEvent) in
   // invoked when the response event for `triggerEvent` is dispatched through the `EventHub`
}
```

#### Extension Public APIs

##### Defining the public APIs for an `Extension`

Extensions should define their public APIs within a `protocol`, which is implemented by the class that also conforms to the `Extension` protocol.

All APIs should be static, and for APIs that return a value, _most_ should provide those values in the form of an asynchronous callback. Each API definition should provide clear documentation about it's behavior and the required parameters.

##### Public API Definition Example

```swift
protocol Identity {
    /// Appends visitor information to the given URL.
    /// - Parameters:
    ///   - url: URL to which the visitor info needs to be appended. Returned as is if it is nil or empty.
    ///   - completion: closure which will be invoked once the updated url is available.
    static func appendTo(url: URL?, completion: @escaping (URL?) -> ())

    /// Returns all customer identifiers which were previously synced with the Adobe Experience Cloud.
    /// - Parameter completion: closure which will be invoked once the customer identifiers are available.
    static func getIdentifiers(completion: @escaping ([MobileVisitorId]?) -> ())
}
```

##### Implementing your public APIs

Most implementations of public APIs should be lightweight, usually just dispatching an `Event` to your extension, and occasionally listening for a response `Event` to provide a returned value.

We recommend creating an `extension` on your class, which conforms to `Extension` to implement your API protocol.

```swift
extension AEPIdentity: Identity {
  // implement your public APIs
}
```

##### APIs that don't return a value

APIs that only result in an action being taken and no value being returned can usually be implemented in just a few lines. In the following example the `AEPConfiguration` extension is listening for an `Event` of type `configuration` and source `requestContent` with the app id payload. When the `AEPConfiguration` extension receives this `Event` it will carry out the required processing to configure the SDK with the given `appId` and potentially dispatch other events and update it's shared state. 

```swift
extension AEPCore: Configuration {
    public static func configureWith(appId: String) {
        let event = Event(name: "Configure with AppId", type: .configuration, source: .requestContent,
                          data: [ConfigurationConstants.Keys.JSON_APP_ID: appId])
        AEPCore.dispatch(event: event)
    }
}
```

##### APIs that return a value

For APIs that return a value, response listeners should be used. In the following example the API dispatches an `Event` to the `AEPConfiguration` extension, which results in a response `Event` being dispatched with the privacy status stored in the event data, subsequently notifying the response listener.

```swift
extension AEPCore: Configuration {
      public static func getPrivacyStatus(completion: @escaping (PrivacyStatus) -> ()) {
        let event = Event(name: "Privacy Status Request", type: .configuration, source: .requestContent, data: [ConfigurationConstants.Keys.RETRIEVE_CONFIG: true])

        EventHub.shared.registerResponseListener(parentExtension: AEPConfiguration.self, triggerEvent: event) { (responseEvent) in
            self.handleGetPrivacyListener(responseEvent: responseEvent, completion: completion)
        }

        AEPCore.dispatch(event: event)
    }
}
```

The general pattern for getters follows:

1. Create an `Event` which will result in your extension dispatching a response `Event`.
2. Register a response listener for the newly created request `Event`.
3. Dispatch the request `Event`.
4. Handle the returned value within the response listener.

#### Event Processing (TBD)

One of the most fundamental responsibilities for an extension is to process incoming events; these events often represent APIs being invoked. Extensions should only process one `Event` at a time, in a synchronous manner. To assist with this requirement, we provide a utility class `OperationOrderer`. The `OperationOrderer` allows for an extension to synchronously process events and decide if it should pause and wait for incoming data (potentially shared state) or proceed to the next `Event`.

##### `EventHandlerMapping`

A convenience type definition of `EventHandlerMapping` exists in the `EventHub`, which is defined as a tuple containing an `Event` and a reference to a function that takes in an `Event` and returns a `Bool`.

```swift
public typealias EventHandlerMapping = (event: Event, handler: (Event) -> (Bool))
```

##### Creating the `OperationOrderer`

```swift
// create
private let eventQueue = OperationOrderer<EventHandlerMapping>(ConfigurationConstants.EXTENSION_NAME)
```

After creating an `OperationOrderer,` you must set the `handler`. The `handler` is a function that takes in an `Event` and returns a `Bool` indicating if `Event` processing should continue (`true`) or pause (`false`).

In the following example we make use of the `EventHandlerMapping`, so that when we queue an `Event`, we also provide the associated function which will process that `Event`, this associated function returns a `Bool`.

```swift
eventQueue.setHandler({ return $0.handler($0.event) })
```

##### Adding an Event to the `OperationOrderer`

When an extension receives a new `Event` it can add the `Event` and the corresponding function to handle it.

```swift
private func receiveConfigurationRequest(event: Event) {
    eventQueue.add((event, handleConfigurationRequest(event:)))
}
```

##### Processing an Event

As we have built up to this point, we have declared that any configuration request event will be handled by a new function `handleConfigurationRequest()`

```swift
private func handleConfigurationRequest(event: Event) -> Bool {
   // process event, return true to continue to next event, false to pause the queue
}
```

##### Restarting the Queue

There are a few ways the queue will come back online and attempt to process the next `Event` if it is currently paused.

1. A new `Event` is added to the queue
2. `eventQueue.start()` is invoked

#### Shared States

Extensions use events and shared states to communicate with each other. The events allow extensions to be relatively decoupled, but shared states are necessary when an extension has a dependency on data provided by another extension.

A Shared State is composed of the following:

- The name of the extension who owns it
- The status of the Shared State defined as a `SharedStateStatus` (none, pending, set)
- An `Event` , which is an event that contains data that an extension wants to expose to other extensions

**Important**: Every `Event` does not result in an updated shared state. Shared states have to be explicitly set, which causes the `EventHub` to notify other extensions that your extension has published a new shared state.

##### Updating Shared State

By default, every extension is provided with an API to update their shared state with new data. Pass in the data and optional `Event` associated with the shared state, and the `EventHub` will update your shared state and dispatch an `Event` notifying other extensions that a new shared state for your extension is available.

```swift
/// Creates a new `SharedState for this extension
/// - Parameters:
///   - data: Data for the `SharedState`
///   - event: An event for the `SharedState` to be versioned at, if nil the shared state is versioned at the latest
func createSharedState(data: [String: Any], event: Event?)
```

##### Creating and Updating a Pending Shared State

In some cases, an extension may want to declare that its shared state is currently pending. For example, an extension may be doing some data manipulation, but in the meantime, the extension may invalidate its existing shared state and notify other extensions that the extension is currently working on providing a new shared state. This can be done with the API `func createPendingSharedState(event: Event?) -> SharedStateResolver`. This function creates a pending shared state versioned at an optional `Event` and returns a closure, which is to be invoked with your updated shared state data once available.

###### Pending Shared State Example

```swift
// set your current Shared State to pending
let pendingResolver = createPendingSharedState(event: nil)

// compute your new Shared State data
let updatedSharedStateData = computeSharedState()

// resolve your pending Shared State
pendingResolver(updatedSharedStateData)
```

##### Reading Shared State from another Extension

All extensions are provided a default API to read shared state from another extension. Simply pass in the name of the extension and the optional `Event` to get an extension's shared state.

```swift
/// Gets the `SharedState` data for a specified extension
/// - Parameters:
///   - extensionName: An extension name whose `SharedState` will be returned
///   - event: If not nil, will retrieve the `SharedState` that corresponds with the event's version, if nil will return the latest `SharedState`
func getSharedState(extensionName: String, event: Event?) -> (value: [String: Any]?, status: SharedStateStatus)?
```

##### Listening for Shared State Updates

In some instances an extension may want to be notified of when an extension publishes a new shared state, to do this an extension can register a listener which listens for an `Event` of type `hub` and source `sharedState`, then it can inspect the event data to determine which extension has published new shared state.

```swift
registerListener(type: .hub, source: .sharedState) { (event) in
    guard let stateOwner = event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as? String else { return }
    // check if stateOwner is equal to the Extension whose Shared State you need
}
```

#### Testing an Extension

TODO
