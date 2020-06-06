
import Foundation
import AEPCore
@testable import SampleExtension

struct ExtensionRuntimeEnv{
    var listernerMapping: [String: Array<EventListener>] = [:]
    var receivedEvents: [Event] = []
    
    
    public static var shared = ExtensionRuntimeEnv()
    
    mutating func registerListener(type: EventType, source: EventSource, listener: @escaping EventListener){
        let listerns = listernerMapping[type.rawValue + source.rawValue] ?? []
        listernerMapping[type.rawValue + source.rawValue] = listerns + [listener]
    }
    
    func simulateEvent(type: EventType, source: EventSource, event: Event){
        let listerns = listernerMapping[type.rawValue + source.rawValue] ?? []
        listerns.forEach { listener in
            listener(event)
        }
    }
    
    mutating func dispatch(event: Event) {
        receivedEvents += [event]
    }
    
    func createSharedState(extensionName:String, data: [String: Any], event: Event?) {
    }
    
    func createPendingSharedState(extensionName:String,event: Event?) -> SharedStateResolver {
        return  { data in
        }
    }
    
    func getSharedState(extensionName: String, event: Event?) -> (value: [String: Any]?, status: SharedStateStatus)? {
        return (nil, .none)
    }
    
}
