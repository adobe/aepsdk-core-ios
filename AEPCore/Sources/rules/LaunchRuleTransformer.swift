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

import AEPServices
import Foundation
import AEPRulesEngine

/// generate the `Transforming` instance used by Launch Rules Engine
class LaunchRuleTransformer {

    let transformer: Transformer
    let runtime: ExtensionRuntime

    init(runtime: ExtensionRuntime) {
        self.transformer = Transformer()
        self.runtime = runtime
        addFunctionalTransformations(to: self.transformer)
        addTypeTransformations(to: self.transformer)
    }

    private func addFunctionalTransformations(to transform: Transformer) {
        // adds the transformer for the url encoding function
        transform.register(name: RulesConstants.Transform.URL_ENCODING_FUNCTION_IN_RULES, transformation: { value in
            if let valueString = value as? String {
                return URLEncoder.encode(value: valueString)
            }
            return value
        })

        // adds the transformer for querying event history in the database
//        transform.register(name: RulesConstants.Transform.EVENT_HISTORY_IN_RULES, transformation: { value in
//            var returnValue = 0
//            
//            // value is a JSONHistoricalEvent object represented as a JSON string
//            guard let eventString = value as? String,
//                  let event = try? JSONDecoder().decode(JSONHistoricalEvent.self, from: eventString.data(using: .utf8) ?? Data()) else {
//                return returnValue
//            }
//            
//            // convert array of JSONHistoricalEvent into an array of EventHistoryRequests
//            let request = EventHistoryRequest(event)
        ////            let requests = events.map { event in
        ////                EventHistoryRequest(event)
        ////            }
//            
//            let semaphore = DispatchSemaphore(value: 0)
//            
//            self.runtime.getHistoricalEvents([request], enforceOrder: false /* requests.count > 1 */) { results in
//                if results.count == 1 {
//                    if let count = results.first?.count {
//                        returnValue = count
//                    }
//                } else if results.count > 1 {
//                    for result in results {
//                        returnValue = result.count
//                        if returnValue == 0 {
//                            break
//                        }
//                    }
//                }
//                
//                semaphore.signal()
//            }
//            semaphore.wait()
//            return returnValue
//        })
    }

    private func addTypeTransformations(to transform: Transformer) {
        transform.register(name: RulesConstants.Transform.TRANSFORM_TO_INT, transformation: { value in
            switch value {
            case is String:
                if let stringValue = value as? String, let intValue = Int(stringValue) { return intValue}
            case is Double:
                if let doubleValue = value as? Double { return Int(doubleValue) }
            case is Bool:
                if let boolValue = value as? Bool { return boolValue ? 1:0}
            default:
                return value
            }
            return value
        })

        transform.register(name: RulesConstants.Transform.TRANSFORM_TO_STRING, transformation: { value in
            return String(describing: value)
        })

        transform.register(name: RulesConstants.Transform.TRANSFORM_TO_DOUBLE, transformation: { value in
            switch value {
            case is String:
                if let stringValue = value as? String, let doubleValue = Double(stringValue) { return doubleValue}
            case is Int:
                if let intValue = value as? Int { return Double(intValue)}
            case is Bool:
                if let boolValue = value as? Bool { return boolValue ? 1.0:0.0}
            default:
                return value
            }
            return value
        })

        transform.register(name: RulesConstants.Transform.TRANSFORM_TO_BOOL, transformation: { value in
            switch value {
            case is String:
                if let stringValue = value as? String { return stringValue.lowercased() == "true"}
            case is Double:
                if let doubleValue = value as? Double { return doubleValue == 1}
            case is Int:
                if let intValue = value as? Int { return intValue == 1 }
            default:
                return value
            }
            return value
        })
    }
}
