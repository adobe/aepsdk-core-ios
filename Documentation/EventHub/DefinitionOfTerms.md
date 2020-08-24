# Definition of Terms

- [Event](#event)
- [Event Data](#event-data)
- [Event Hub](#event-hub)
- [Event Listener](#event-listener)
- [Event Source](#event-source)
- [Event Type](#event-type)
- [Extension](#extension)
- [Pending Shared State](#pending-shared-state)
- [Shared State](#shared-state)
- [Shared State Resolver](#shared-state-resolver)

--------------------------------------------------------------------------------
#### [Event](Event.md)

The object used to pass data through the **Event Hub**. An Event is defined by a combination of its **Event Data**, **Event Source**, and **Event Type**. An Event contains the data necessary for registered **Extensions** to determine if and how they should respond to the Event. Events can originate externally from public API calls, or internally from the Event Hub or registered Extensions.

--------------------------------------------------------------------------------
#### Event Data            

A dictionary (`[String: Any]`) of values containing data specific to the **Event**. The Event Data helps interested **Extensions** know _how_ the Event should be handled.

--------------------------------------------------------------------------------
#### Event Hub

The controller of the SDK. The Event Hub is responsible for receiving Events, maintaining their correct order, and passing them along to any interested Extension.

--------------------------------------------------------------------------------
#### Event Listener

A mechanism by which an Extension can indicate to the Event Hub that it is interested in knowing about Events that match a specific criteria. Event Listeners are unique per Extension, Event Source, and Event Type.

--------------------------------------------------------------------------------
#### Event Source

A value that indicates the reason for the Event's creation. e.g. - `com.adobe.eventSource.requestContent`

--------------------------------------------------------------------------------
#### Event Type

A value that indicates from which Extension an Event originated. e.g. - `com.adobe.eventType.identity`

--------------------------------------------------------------------------------
#### Extension

An independent collection of code that can be registered by the Event Hub. An Extension's primary roles are handling and creating Events. An extension is responsible for registering one or more Event Listeners with the Event Hub.

--------------------------------------------------------------------------------
#### Pending Shared State

A Shared State that has been created, but has not yet been populated by the owning Extension. A pending shared state is a way for an Extension to indicate that it will have a valid Shared State for this Event in the future. An Extension may choose to create a pending shared state when it knows it will have data to share, but has some other task to complete first before the state can be generated (e.g. - getting a response from an asynchronous network call).

--------------------------------------------------------------------------------
#### Shared State

A mechanism that allows Extensions to share state data with other Extensions. Specifically, any data existing in a shared state should be considered valid by all other Extensions until it is either overwritten or removed by the owning extension. Shared states are owned by the Event Hub, but maintained by the Extension that owns them.

--------------------------------------------------------------------------------
#### Shared State Resolver

A `typealias` of `([String: Any]?) -> Void`. A shared state resolver is used when an extension knows it will need to create a shared state for a specific event, but it doesn't yet have the data that it needs to share. Once the extension has completed its work, it calls the shared state resolver with the necessary data.
