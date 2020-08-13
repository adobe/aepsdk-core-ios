# Event Hub Contract

# Glossary:

### Event:

### Event Hub:

### Shared State:

### Event Listener:

## Contract


### Event hub:
- Event hub itself is not accessible, you can interact with it through `MobileCore` class or Extension's API.
- When initialize the event hub, the set of the extension class need to be passed to it. Currently we do not support dynmaically add or remove an extension. 
- Once all the extensions's `onRegistered()` have finished, the event hub is considered booted and it begins to distribue events to each extensiosn.

In the following docs, assuming the events coming in the order of:

E1 → E2 → E3 → .... → EN1 → EN2 → EN3 → EN4 → .......

### Extension:

- Extension owns a dispatch queue.
- All the listeners from the same extension are running on the same dispatch queue
- It is impossible that two listeners will be running simultaneously

### Registration:

- All the extensions are being registered at the same time, simultaneously, when the public `start` method gets called.
- init() always runs before onRegistered()
- Avoid reading shared state of any other extension during initialization or registration.
- Do minimal job in init()
- Register listeners, init data queues, read local storage inside onRegister
- The order of extensions registration is unknown

### UnRegistration:

     No supported yet.

### SharedState:

- Each extension has its sharedstate, identified by the extensions's name
- When you receive EN1, you can can set to shared state for EN1 to `.pending`, so any other extension depending on the shared state of the current extension will be blocked. Once the extension finished processing,  set the shared state to `.set` with a valid data, it will also unblock other extensions.
- If you don't want your extension block another extension,  do not set a `.pending` state.
- You can  set shared state for EN2 after setting shared state for EN1.
- Once you have  set shared state for EN2, you will not be allowed to set shared state for EN1.
- If ExtensionB has a dependency on  ExtensionA's shared state, use `readyForEvents` to check the status of the ExtensionA's shared state.


### Event:

- Events triggered before event hub booted will be cached and then distributed to each extension once the registration finished, so for each extension it will receive the events in the same order of `E1 → E2 → E3`
- For a extension, the events will always be received in the order, `E1 → E2 → E3 → .... → EN1 → EN2 → EN3 → EN4 → .......`
- The time taken to processed a event by different extensions is unknown
- How fast each an extension can process the events is unknown, so it could be possible one extension has process EN4 while another extension is still on EN1.

### Start and Stop Events:

- Once the `stopEvents` is called, the extension will pause handling events, so even when there is Event matched to a listener, the listener will not get it until `startEvents` get called.
- Use `stopEvents` and `startEvents` when waiting for some data asynchronously, or some other reason when you want to pause the event handling.
- The initial state of an extension is start, so you don't need to call `startEvents`  during init or registration.