/*
Copyright 2020 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/

import Foundation
import AEPServices

/// An Event to be dispatched by the Event Hub
public struct Event {
    
    /// Name of the event
    let name: String
    
    /// unique identifier for the event
    private(set) var id = UUID()
    
    /// The `EventType` for the event
    let type: EventType
    
    /// The `EventSource` for the event
    let source: EventSource
    
    /// Optional data associated with this event
    let data: [String: Any]?
    
    /// Date this event was created
    private(set) var timestamp = Date()
    
    /// If `responseID` is not nil, then this event is a response event and `responseID` is the `event.id` of the `triggerEvent`
    let responseID: UUID?
    
    /// Creates a new `Event` with the given parameters
    /// - Parameters:
    ///   - name: Name for the `Event`
    ///   - type: `EventType` for the `Event`
    ///   - source: `EventSource` for the `Event`
    ///   - data: Any associated data with this `Event`
    public init(name: String, type: EventType, source: EventSource, data: [String: Any]?) {
        self.init(name: name, type: type, source: source, data: data, requestEvent: nil)
    }
    
    private init(name: String, type: EventType, source: EventSource, data: [String: Any]?, requestEvent: Event?) {
        self.name = name
        self.type = type
        self.source = source
        self.data = data
        self.responseID = requestEvent?.id
    }

    /// Creates a new `Event` where the `responseID` is equal to the `id` of this `Event`
    /// - Parameters:
    ///   - name: Name for the `Event`
    ///   - type: `EventType` for the `Event`
    ///   - source: `EventSource` for the `Event`
    ///   - data: Any associated data with this `Event`
    func createResponseEvent(name: String, type: EventType, source: EventSource, data: [String: Any]?) -> Event {
        return Event(name: name, type: type, source: source, data: data, requestEvent: self)
    }
    
}

extension Event: Decodable, Encodable {
    enum CodingKeys: String, CodingKey {
        case name
        case id
        case type
        case source
        case data
        case timestamp
        case responseID
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try values.decode(String.self, forKey: .name)
        id = try values.decode(UUID.self, forKey: .id)
        type = try values.decode(EventType.self, forKey: .type)
        source = try values.decode(EventSource.self, forKey: .source)
        let anyCodableDict = try values.decode([String: AnyCodable].self, forKey: .data)
        data = AnyCodable.toAnyDictionary(dictionary: anyCodableDict)
        timestamp = try values.decode(Date.self, forKey: .timestamp)
        responseID = try values.decode(UUID.self, forKey: .responseID)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(source, forKey: .source)
        try container.encode(AnyCodable.from(dictionary: data), forKey: .data)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(responseID, forKey: .responseID)
    }
}
