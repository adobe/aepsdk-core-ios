

# Architecture

Adobe Experience SDK is built with an open, extensible, product-agnostic, event-stream based architecture. Similar to well-known [Event-driven architectures](https://en.wikipedia.org/wiki/Event-driven_architecture), it uses events to trigger and communicate between independent extensions. This architecture supports building an ecosystem where both Adobe and third-party partners can build SDK extensions that provide valuable services to the customers.

Reviewing the [Definition of Terms](EventHub/DefinitionOfTerms.md) is recommended for a better understanding of terminologies that will be used in the remainder of this document.

## Event Streaming

![Events stream](https://app.lucidchart.com/publicSegments/view/e720c862-bb1d-4aab-b663-7fe5ae1aa53a/image.png)

An Event is the start of a process. It can represent any action, and must be run inside of the event loop to maintain event order integrity. Events can originate from many locations. For example, the developer providing data to the SDK via a public API, or an SDK extension publishing its data that other extensions may find useful.

The **Event Hub** is the controller of the SDK. The Event Hub is responsible for receiving **Events**, maintaining their correct order, and passing them along to interested **Extensions**. It creates and maintains an **Extension Container** instance for each registered Extension and forwards events to the containers. Extension Containers holds the instance of their corresponding Extensions. When an Event enters the container, the container is responsible for delivering the Event to any matching Listener for the Extension.

## Core Structure

This diagram illustrates how Extension Containers work as an intermediator between the Event Hub and Extensions.

![Extension Container](https://app.lucidchart.com/publicSegments/view/488c0d86-8134-4952-ab38-4a9d7a244cb8/image.png)

There are four main responsibilities of the Extension Container:

1. **_Access to extension lifecycle control_** - The Event Hub controls the lifecycle of an Extension Container. In turn, the Container controls the lifecycle of its paired Extension.  
2. **_Providing an Extension Runtime_** - Extensions do not directly interact with the Event Hub. Instead, the Container creates and provides an Extension Runtime instance to its Extension. The Extension Runtime allows Extensions to register Listeners, dispatch Events, read and write shared states, and start/stop Event processing.
3. **_Maintain Event Listeners_** - For each Event Listener registered by the Extension, the Extension Container creates a mapped Listener Container. When an Event is dispatched from the Event Hub, Extension Containers pass the event to any matching listener(s).
4. **_Threading_** - Each Container is backed by a Dispatch Queue. This allows all the Extensions to run in parallel. Extensions can temporarily stop Events from processing by calling the `start` or `stop` APIs provided by the Extension Runtime.

## Module Layers

![Module Layers](https://app.lucidchart.com/publicSegments/view/3677075f-e932-49e9-96c1-1b16cc66fb8c/image.png)

#### Extensions

Extensions are the heavy lifters for each feature/solution. They are responsible for transforming the Event into an action. For example, the AEPAnalytics extension transforms an Event into an eventual network request sent to an Analytics server.

Adobe provides extensions to work with Adobe Experience Cloud solutions, including Platform, Analytics, Target, and Audience Manager. Any partner or any developer can also build their services as an extensions and integrate with Adobe's ecosystem.  

#### AEPCore

AEPCore is the heart of the AEP SDK. It includes the [Event Hub](./EventHub/README.md), the Configuration extension, and the Rules Engine. It defines the `Extension` protocol, from which all Extensions must inherit. It also creates an `ExtensionRuntime` instance for each Extension, allowing interactions between Extensions and the Event Hub.

AEPCore provides public APIs that are fundamental for configuring, starting, and running the SDK.

#### AEPServices

AEPServices module adopts a simplified Service Provider pattern providing platform services that are needed by AEPCore and other extensions. These services include access to networking, file i/o, local storage, database management and more. It also contains some helpful utility classes, like thread-safe dictionary and array, a hit processor, and others.

The AEPServices module allows overriding of certain services to allow more flexibility for app developers.
