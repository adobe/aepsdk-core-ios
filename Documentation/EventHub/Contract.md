# EventHub Contract

# Glossary:

### Event:

### EventHub:

### Shared State:

### Event Listener:

## Contract


### EventHub:
- EventHub itself is not accessible, interact with it by calling the methods from the `MobileCore` class or the Extension's API.
- When initializing the EventHub, the set of the initial extension classes need to be passed to it. 
- Once all the initial extensions's `onRegistered()` have finished, the EventHub is considered booted and it begins to distribute events to every extension.
- Currently, dynamically adding or removing of extensions is not supported. 

In the following docs, assuming the events coming in the order of:

E1 → E2 → E3 → .... → EN1 → EN2 → EN3 → EN4 → .......

### Extension:

- Extension owns a dispatch queue.
- All the listeners from the same extension are running on the same dispatch queue.
- It is impossible that two listeners from the same extension can be running simultaneously.

### Extension Registration:

- All the initial extensions are being registered at the same time, simultaneously, when the public `start` method gets called.
- `init()` always runs before `onRegistered()`
- The order of extensions registration is unknown, how fast an extension can finish its registration is unknown.

### UnRegistration:

     Not supported yet.

### Shared State:

- Each extension has its own shared state, identified by the extensions's name.
- An extension can set the shared state for EN2 after setting shared state for EN1.
- Once an extension have set the shared state for EN2, it will not be allowed to set the shared state for EN1.
- `nil` is returned when trying to get a shared state for an extension which is not registered.
- `.none` status returned when trying to get a shared state for an extension but it has not set anything yet.
- If the last shared state ExtensionA has been set is for EN1 is ShareStateEN1 (no matter `.set` or `.pending`), ShareStateEN1 is returned when trying to get shared state for EN1, or EN2 or any events after.
- If ExtensionA has set shared state for EN1 with ShareStateEN1 and for EN2 with ShareStateEN2, ShareStateEN1 is returned when trying to get shared state for EN1.
- If ExtensionA has set shared state for EN1 with ShareStateEN1 and for EN4 with ShareStateEN4, ShareStateEN1 is returned when trying to get shared state for EN1, EN2 and EN3.
- If the first shared set by ExtensionA is for EN1 with ShareStateEN1, ShareStateEN1 is returned when trying to get shared state for E1, E2 E3 and any event triggered before EN1.


### Event:

- Events triggered before EventHub booted will be cached and then distributed to each extension once the registration finished, so for each extension it will receive the events in the same order of `E1 → E2 → E3 → ....`
- For an extension, the events will always be received in the order, `E1 → E2 → E3 → .... → EN1 → EN2 → EN3 → EN4 → .......`
- The time that different extensions take to process the same event is unknown
- How fast each extension can process the events is unknown, so it could be possible one extension is processing EN4 while another extension is still on EN1.

### Start and Stop Events:

- Once the `stopEvents` API is called, the extension will pause handling events, so even when there is an event matched to a listener, the listener will not receive it until `startEvents` get called.
- Use `stopEvents` and `startEvents` when waiting for some data asynchronously, or some other reason when you want to pause the event handling.
- The initial state of an extension is started, so you don't need to call `startEvents`  during init or registration.