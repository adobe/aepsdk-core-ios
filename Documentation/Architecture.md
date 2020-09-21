

# Architecture

Adobe Experience SDK is built with an open, extensible, product-agnostic, event-stream based architecture. Similar like well-known [Event-driven architecture](https://en.wikipedia.org/wiki/Event-driven_architecture), it uses events to trigger and communicate between decoupled extensions. It helps us build up a eco-system, where not only Adobe involves in, 3rd party partners can also easily build extensions and  provide valuable services to the customers.

Before moving on, read the Definition of Terms to get a better understanding of some terminologies will be used in this page.

## Event Streaming

![Events stream](https://app.lucidchart.com/publicSegments/view/e720c862-bb1d-4aab-b663-7fe5ae1aa53a/image.png)

An event is the start of the process. This is any action that occurs that requires the event loop to be run. Events can originate from the customer handing the sdk data, or one of the extensions publishing data it thinks other extensions may care about.

Event Hub is the controller of the SDK. The Event Hub is responsible for receiving **Events**, maintaining their correct order, and passing them along to any interested **Extension**. It creates and maintains an Extension Container instance for each registered Extensions, and forward all the events to every container. Extension Container holds the instance of the corresponding Extension, and when an event comes in it delievers the event to the extension listener if there is a match.



## Core Structure

This diagram shows the relationship between Event Hub, Extension Container and Extension, and how Extension Container works as a intermediator. 

![Extension Container](https://app.lucidchart.com/publicSegments/view/488c0d86-8134-4952-ab38-4a9d7a244cb8/image.png)

There are four main responsiblilties of Extension Container:

1. Lifecyle delegate. EventHub controls the lifecycle of Container, and Container in turn controls the lifecycle Extensions.  
2. Extension Runtime. Extension doesn't direclty interact with Event Hub, instead Container creates and provides a Extension Runtime instance to Extension. With it, extension can register listeners, dispatch events,  get or udpate shared states, and start or stop the event processing.
3. Listeners. For each event listener registered by the extension, Container creates a 1:1 mapped Listener Container. And when a event is distributed from Event Hub, Container eveluate if there is a matched listener, and passes the event to the listener if so.
4. Threading. Each Container is backed by a Dispatch Queue, so all the extensions are running parallel. Extension can even control temporaily stop the events processing by calling start or stop API provided by the Extension Runtime.





## Module Layers

![Module Layers](https://app.lucidchart.com/publicSegments/view/3677075f-e932-49e9-96c1-1b16cc66fb8c/image.png)

#### AEPServices

AEPServices module adopts a simplied Service Provider pattern to provide platform services that are needed by AEPCore and other extensions. It also allows overriding of certain services, gives more flexibility to the app developers. 

AEPServices module also contains some utitlity classes, like thread-safe dictionary and array, hit proccessor etc..

#### AEPCore

AEPCore is the heart of the AEP SDK. It includes  [Event Hub](./EventHub/README.md), Configuration, Rules Engine. It defines the `Extension ` protocol, which all the extension has to inheritate from, and creates `ExtensionRuntime` instance for each extension to interact with Event Hub. 

 AEPcore also provides fundamental APIs to start and run the SDK.

#### Extensions

Extensions are the heavy lifters for each feature/solution, they are responsible for handling transforming the event into an action (ex. Event to Analytics Hit).

Adobe provides extensions to work with solutions of Adobe Experience Cloud, including Analytics, Target, Audience Manager, Campaign and so on. Any partener or any develper can also built their services as an extensions and integrate with Adobe's ecosystem.  

