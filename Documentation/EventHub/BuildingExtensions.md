# Building Extensions

Extensions allow developers to extend the Experience Platform SDKs with their code. Building an extension includes listening for and dispatching events, reading the shared state of any registered extension, and sharing the state of the current extension. The application can use the extension to monitor for information that Adobe does not expose by default. It can also use the extension to modify Experience Platform SDK internal operations, for example, by adding additional data to messages that are sent or by sending data to other systems.

This document covers the high level concepts about developing your own extension.

#### Defining an Extension

For an extension to be registered with the `EventHub`, it must conform to the `Extension` protocol. The `Extension` protocol defines an `Extension` as a type which provides a initializer which takes in a `ExtensionRuntime`, a  `name`, `friendlyName`, `version`, `metadata` and implements three methods: `onRegistered()`, `onUnregistered()`, and `readyForEvent()`.

See [`Extension.swift`](https://github.com/adobe/aepsdk-core-ios/blob/master/Sources/eventhub/Extension.swift) for the complete definition.

> Note: Some of the APIs found in the `Extension` class are part of a Swift `extension` and are therefore not visible in Objective-C. If the extension is being implemented in Objective-C rather than Swift, you must use the `ExtensionRuntime` directly instead of the `extension Extension` APIs. E.g: `runtime.dispatch(event: event)` instead of `dispatch(event: event)` from within the `Extension` implementation.  

#### Events

##### Purpose of an `Event`

- Triggering actions in the Experience Platform SDKs. Events are used by the extensions to signal when specific actions should occur, for example, to send an Analytics hit. Extensions can send the same types of events that the Experience Platform SDKs would send internally to trigger these actions.
- Triggering actions in another extension. Some applications might have multiple extensions, and some of these extensions might have their events defined that trigger actions.

##### Creating an `Event`

```swift
let event = Event(name: "Configuration Request Event", type: EventType.configuration, source: EventSource.requestContent, data: data)
```

##### Creating a response `Event`

```swift
let triggerEvent: Event = ...
let responseEvent = triggerEvent.createResponseEvent(name: "Configuration Response Event", type: EventType.configuration, source: EventSource.responseContent, data: data)
```

#### Dispatching Events

Extensions can dispatch an `Event` to the `EventHub` via the `dispatch(event: Event)` API, which is provided by default to all classes that implement `Extension`. This API will result in all listeners whose `EventType` and `EventSource` match to be invoked with the `event`.

```swift
let event = Event(name: "My Event", type: EventType.analytics, source: EventSource.requestContent, data: data)
dispatch(event: event)
```

##### Dispatching response Events

Occasionally, an extension may want to dispatch a response event for a given `Event`, to do this an extension must first create the response `Event` from the trigger `Event`, then dispatch it through the `EventHub`, this will notify any response listeners registered for `triggerEvent`

```swift
let triggerEvent: Event = ...
let responseEvent = triggerEvent.createResponseEvent(name: "Configuration Response Event", type: EventType.configuration, source: EventSource.responseContent, data: data)
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
registerListener(type: String, source: String, listener: @escaping EventListener)

// Registers an `EventListener` with the `EventHub` that is invoked when `triggerEvent`'s response event is dispatched
registerResponseListener(triggerEvent: Event, listener: @escaping EventListener)
```

> Note: Registering listeners should be done in the `onRegistered()` function of an extension.

##### Listener Example

```swift
// receiveConfigurationRequest is invoked whenever the `EventHub` dispatches an event with type configuration and source request content
registerListener(type: EventType.configuration, source: EventSource.requestContent, listener: receiveConfigurationRequest(event:))

private func receiveConfigurationRequest(event: Event) {
   // handle event
}

// Can also be implemented with a closure
registerListener(type: EventType.configuration, source: EventSource.requestContent) { (event) in
   // handle event            
}
```

##### Wildcard Listeners

Some extensions may have the requirement to be notified of all events that are dispatched from the `EventHub`, in this case, a `wildcard` `EventType` and `EventSource` are available.

```swift
// Invoked for all events that are dispatched from the `EventHub`
registerListener(type: EventType.wildcard, source: EventSource.wildcard) { (event) in
   // handle event            
}
```

##### Response Listeners

Response listeners allow extensions to listen for the response event of a given trigger `Event`. Response listeners are only invoked once, and will be invoked with a `nil` `Event` if a response event for `triggerEvent` is not dispatched in time.

```swift
let triggerEvent = Event(name: "Trigger Event", type: .identity, source: .requestIdentity, data: nil)

registerResponseListener(triggerEvent: triggerEvent, timeout: 1) { (responseEvent) in
   // invoked when the response event for `triggerEvent` is dispatched through the `EventHub`
}
```

#### Extension Public APIs

##### Defining the public APIs for an `Extension`

Extensions should define their public APIs within their extension class or in an `extension` on the class. All APIs should be static, and for APIs that return a value, _most_ should provide those values in the form of an asynchronous callback. Each API definition should provide clear documentation about it's behavior and the required parameters.

##### Public API Definition Example

```swift
/// Defines the public interface for the Identity extension
@objc public extension Identity {
    /// Appends visitor information to the given URL.
    /// - Parameters:
    ///   - url: URL to which the visitor info needs to be appended. Returned as is if it is nil or empty.
    ///   - completion: closure which will be invoked once the updated url is available, along with an error if any occurred
    static func appendTo(url: URL?, completion: @escaping (URL?, AEPError) -> Void) {
			// ...
    }
}
```

##### Implementing your public APIs

Most implementations of public APIs should be lightweight, usually just dispatching an `Event` to your extension, and occasionally listening for a response `Event` to provide a return value.

##### APIs that don't return a value

APIs that only result in an action being taken and no value being returned can usually be implemented in just a few lines. In the following example the `AEPConfiguration` extension is listening for an `Event` of type `EventType.configuration` and source `EventSource.requestContent` with the app id payload. When the `Configuration` extension receives this `Event` it will carry out the required processing to configure the SDK with the given `appId` and potentially dispatch other events and update it's shared state.

```swift
@objc public extension MobileCore {
    /// Configure the SDK by downloading the remote configuration file hosted on Adobe servers
    /// specified by the given application ID. The configuration file is cached once downloaded
    /// and used in subsequent calls to this API. If the remote file is updated after the first
    /// download, the updated file is downloaded and replaces the cached file.
    /// - Parameter appId: A unique identifier assigned to the app instance by Adobe Launch
    static func configureWith(appId: String) {
        let event = Event(name: "Configure with AppId", type: EventType.configuration, source: EventSource.requestContent,
                          data: [CoreConstants.Keys.JSON_APP_ID: appId])
        MobileCore.dispatch(event: event)
    }
}
```

##### APIs that return a value

For APIs that return a value, response listeners should be used. In the following example the API dispatches an `Event` to the `AEPConfiguration` extension, which results in a response `Event` being dispatched with the privacy status stored in the event data, subsequently notifying the response listener.

```swift
/// Gets the currently configured `PrivacyStatus` and returns it via `completion`
/// - Parameter completion: Invoked with the current `PrivacyStatus`
@objc(getPrivacyStatus:)
static func getPrivacyStatus(completion: @escaping (PrivacyStatus) -> Void) {
    let event = Event(name: "Privacy Status Request", type: EventType.configuration, source: EventSource.requestContent, data: [CoreConstants.Keys.RETRIEVE_CONFIG: true])

    MobileCore.dispatch(event: event) { (responseEvent) in
        self.handleGetPrivacyListener(responseEvent: responseEvent, completion: completion)
    }
}
```

The general pattern for getters follows:

1. Create an `Event` which will result in your extension dispatching a response `Event`.
2. Register a response listener for the newly created request `Event`.
3. Dispatch the request `Event`.
4. Handle the returned value within the response listener.

#### Event Processing

One of the most fundamental responsibilities for an extension is to process incoming events; these events often represent APIs being invoked. Extensions should only process one `Event` at a time, in a synchronous manner.

##### `readyForEvent`

In many situations when processing an `Event` you will depend upon shared state from antother extension, for example a valid configuration from the Configuration extension. When implementing the `Extension` protocol, you have the option to impelemnt `readyForEvent(Event() -> Bool`, this function is invoked by the `EventHub` each time an `Event` is dispatched and gives extensions the ability to state if they have all the dependencies required to process that specfic `Event`.  

For example, in the Identity extension when processing an `Event` of type `genericIdentity` it requires a valid configuration to exist, so in our implementation of `readyForEvent` we determine if a valid configuration exists before handling the `Event`.

```swift
public func readyForEvent(_ event: Event) -> Bool {
    return getSharedState(extensionName:  IdentityConstants.SharedStateKeys.CONFIGURATION, event: event)?.status == .set
}
```

Once the extension has signaled that it is ready for a given `Event`, the corresponding listener in the extension is notified of the `Event`. `Events` are dispatched to listeners in a synchronous fashion per extension, ensuring that any given extension cannot process more than one `Event` at a time.

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
func getSharedState(extensionName: String, event: Event?) -> SharedStateResult?
```

If you want more control over the reading of the shared state, you can use the overloaded version of the above method:

```swift
/// Gets the `SharedState` data for a specified extension
/// - Parameters:
///   - extensionName: An extension name whose `SharedState` will be returned
///   - event: If not nil, will retrieve the `SharedState` that corresponds with the event's version, if nil will return the latest `SharedState`
///   - barrier: If true, the `EventHub` will only return `.set` if `extensionName` has moved past `event`
///   - resolution: The `SharedStateResolution` to resolve for. E.g: `.lastSet` will resolve for the last set `SharedState`
/// - Returns: A `SharedStateResult?` for the requested `extensionName` and `event`
func getSharedState(extensionName: String, event: Event?, barrier: Bool = false, resolution: SharedStateResolution = .any) -> SharedStateResult?
```

The resolution is used to fetch a specific type of shared state. Using `.any` will just fetch the last shared state, but using `.lastSet`, will fetch the last shared state with a `.set` status. This is useful if you would like to read the cached config before the remote config has been downloaded. 

#### XDM Shared States

XDM shared states allow extensions allow the Edge extension to collect XDM data from various mobile extensions when needed and allow for the creation of XDM data elements to be used in Launch rules. All XDM Shared state data should be modeled based on known / global XDM schema.

##### Updating XDM Shared State

By default, every extension is provided with an API to update their XDM shared state with new data. Pass in the data and optional `Event` associated with the XDM shared state, and the `EventHub` will update your shared state and dispatch an `Event` notifying other extensions that a new shared state for your extension is available. An extension can have none, one or multiple XDM schemas shared as XDM Shared state

```swift
/// Creates a new XDM SharedState for this extension.
/// The data passed to this API needs to be mapped to known XDM mixins; if an extension uses multiple mixins, the current data for all of them should be provided when the XDM shared state is set.
/// If `event` is nil, one of two behaviors will be observed:
/// 1. If this extension has not previously published a shared state, shared state will be versioned at 0
/// 2. If this extension has previously published a shared state, shared state will be versioned at the latest
/// - Parameters:
///   - data: Data for the `SharedState`
///   - event: `Event` for which the `SharedState` should be versioned
func createXDMSharedState(data: [String: Any], event: Event?)
```

##### Creating and Updating a Pending XDM Shared State

In some cases, an extension may want to declare that its shared state is currently pending. For example, an extension may be doing some data manipulation, but in the meantime, the extension may invalidate its existing shared state and notify other extensions that the extension is currently working on providing a new shared state. This can be done with the API `func createPendingXDMSharedState(event: Event?) -> SharedStateResolver`. This function creates a pending shared state versioned at an optional `Event` and returns a closure, which is to be invoked with your updated XDM shared state data once available.

###### Pending Shared State Example

```swift
// set your current Shared State to pending
let pendingResolver = createPendingXDMSharedState(event: nil)

// compute your new XDM Shared State data
let updatedSharedStateData = computeXDMSharedState()

// resolve your pending XDM Shared State
pendingResolver(updatedSharedStateData)
```

##### Reading XDM Shared State from another Extension

All extensions are provided a default API to read XDM shared state from another extension. Simply pass in the name of the extension and the optional `Event` to get an extension's shared state.

```swift
/// Gets the XDM SharedState data for a specified extension. If this extension populates multiple mixins in their shared state, all the data will be returned at once and it can be accessed using path discovery.
/// - Parameters:
///   - extensionName: An extension name whose `SharedState` will be returned
///   - event: If not nil, will retrieve the `SharedState` that corresponds with the event's version, if nil will return the latest `SharedState`
/// - Returns: A `SharedStateResult?` for the requested `extensionName` and `event`
func getXDMSharedState(extensionName: String, event: Event?) -> SharedStateResult?
```

If you want more control over the reading of the shared state, you can use the overloaded version of the above method:

```swift
/// Gets the XDM SharedState data for a specified extension. If this extension populates multiple mixins in their shared state, all the data will be returned at once and it can be accessed using path discovery.
/// - Parameters:
///   - extensionName: An extension name whose `SharedState` will be returned
///   - event: If not nil, will retrieve the `SharedState` that corresponds with the event's version, if nil will return the latest `SharedState`
///   - barrier: If true, the `EventHub` will only return `.set` if `extensionName` has moved past `event`
///   - resolution: The `SharedStateResolution` to resolve for
/// - Returns: A `SharedStateResult?` for the requested `extensionName` and `event`
func getXDMSharedState(extensionName: String, event: Event?, barrier: Bool = false, resolution: SharedStateResolution = .any) -> SharedStateResult?
```

The resolution is used to fetch a specific type of shared state. Using `.any` will just fetch the last shared state, but using `.lastSet`, will fetch the last shared state with a `.set` status. This is useful if you would like to read the cached config before the remote config has been downloaded. 

##### Listening for Shared State Updates

In some instances an extension may want to be notified of when an extension publishes a new shared state, to do this an extension can register a listener which listens for an `Event` of type `hub` and source `sharedState`, then it can inspect the event data to determine which extension has published new shared state.

```swift
registerListener(type: EventType.hub, source: EventSource.sharedState) { (event) in
    guard let stateOwner = event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as? String else { return }
    // check if stateOwner is equal to the Extension whose Shared State you need
}
```

#### Testing an Extension

Testing an extension can be done by using the `TestableExtensionRuntime`, this mock can simulate events to and from the `EventHub`, along with simulating shared state updates. The `TestableExtensionRuntime` can be injected into any extension via the `init?(runtime: ExtensionRuntime)` initializer.



##### Example #1

For the first example, the following tests ensures that the Identity extension dispatches an `Event` with the proper data after it receives a Identity request identity `Event`.

```swift
func testIdentityRequestAppendUrlHappy() {
    // Create our fake `Event` that Identity will receive
    let appendUrlEvent = Event(name: "Test Append URL Event", type: EventType.identity, source: EventSource.requestIdentity, data: [IdentityConstants.EventDataKeys.BASE_URL: "test-url"])
    mockRuntime.simulateSharedState(extensionName: ConfigurationConstants.EXTENSION_NAME, event: appendUrlEvent, data: (["testKey":"testVal"], .set))

		// Simulate that `Event` being dispatched from the `EventHub`
    mockRuntime.simulateComingEvent(event: appendUrlEvent)

    // Inspect any `Event`s the Identity extension has dispatched
    let responseEvent = mockRuntime.dispatchedEvents.first(where: {$0.responseID == appendUrlEvent.id})
    XCTAssertNotNil(responseEvent)
    XCTAssertNotNil(responseEvent?.data?[IdentityConstants.EventDataKeys.UPDATED_URL])
}
```

##### Example #2

In this second example we are testing that the Configuration extension dispatches an `Event` containing the privacy status after receiving a get privacy status `Event`.

```swift
func testGetPrivacyStatusWhenConfigureIsEmpty() {
    // Create our fake `Event`
    let event = createGetPrivacyStatusEvent()

    // Simulate that `Event` being dispatched from the `EventHub`
    mockRuntime.simulateComingEvents(event)

    // Inspect any `Event`s the Configuration extension has dispatched
    XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
    XCTAssertEqual(EventType.configuration, mockRuntime.firstEvent?.type)
    XCTAssertEqual(EventSource.responseContent, mockRuntime.firstEvent?.source)
    XCTAssertEqual(0, mockRuntime.firstEvent?.data?.count)
    XCTAssertEqual(event.id, mockRuntime.firstEvent?.responseID)
}
```
