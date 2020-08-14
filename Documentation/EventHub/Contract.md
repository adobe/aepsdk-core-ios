# Event Hub Contract

# Glossary:

### Event:

### Event Hub:

### Shared State:

### Event Listener:

## Contract


### Event hub:
- Event hub itself is not accessible, you can interact with it through `MobileCore` class or Extension's API.
- When initializing the event hub, the set of the initial extension classes need to be passed to it. 
- Once all the initial extensions's `onRegistered()` have finished, the event hub is considered booted and it begins to distribue events to every extensiosn.
- Currently dynmaically adding or removing of extensions is not supported. 

In the following docs, assuming the events coming in the order of:

E1 → E2 → E3 → .... → EN1 → EN2 → EN3 → EN4 → .......

### Extension:

- Extension owns a dispatch queue.
- All the listeners from the same extension are running on the same dispatch queue.
- It is impossible that two listeners from the same extension can be running simultaneously.

### Extension Registration:

- All the initial extensions are being registered at the same time, simultaneously, when the public `start` method gets called.
- init() always runs before onRegistered()
- The order of extensions registration is unknown, how fast an extension can finish its registration is unknown.

### UnRegistration:

     No supported yet.

### SharedState:

- Each extension has its own sharedstate, identified by the extensions's name.
- You can set the shared state for EN2 after setting shared state for EN1.
- Once you have set the shared state for EN2, you will not be allowed to set the shared state for EN1.
- It returns `nil` when you try to get a shared state for a extension which is not registered.
- It returns shared state as `.none` when you try to get a shared state for an extension but it has not set anything yet.
- If the last shared state ExtensionA has been set is for EN1 is ShareStateEN1 (no matter `.set` or `.pending`), it returns ShareStateEN1 when you try to get shared state for EN1, or EN2 or any events after.
- If ExtensionA has set shared state for EN1 with ShareStateEN1 and for EN2 with ShareStateEN2, it returns ShareStateEN1 when you try to get shared state for EN1.
- If ExtensionA has set shared state for EN1 with ShareStateEN1 and for EN4 with ShareStateEN4, it returns ShareStateEN1 when you try to get shared state for EN1, EN2 and EN3.
- If the first shared set by ExtensionA is for EN1 with ShareStateEN1, it returns ShareStateEN1 when you try to get shared state for E1, E2 E3 and any event triggered before EN1.


### Event:

- Events triggered before event hub booted will be cached and then distributed to each extension once the registration finished, so for each extension it will receive the events in the same order of `E1 → E2 → E3 → ....`
- For a extension, the events will always be received in the order, `E1 → E2 → E3 → .... → EN1 → EN2 → EN3 → EN4 → .......`
- The time that different extensions take to process the same event is unknown
- How fast each extension can process the events is unknown, so it could be possible one extension is processing EN4 while another extension is still on EN1.

### Start and Stop Events:

- Once the `stopEvents` is called, the extension will pause handling events, so even when there is an event matched to a listener, the listener will not receive it until `startEvents` get called.
- Use `stopEvents` and `startEvents` when waiting for some data asynchronously, or some other reason when you want to pause the event handling.
- The initial state of an extension is start, so you don't need to call `startEvents`  during init or registration.