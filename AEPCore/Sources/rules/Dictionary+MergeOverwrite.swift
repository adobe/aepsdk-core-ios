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

struct DictionaryMerger {
    
    private static let SUFFIX_FOR_OBJECT = "[*]"
    
    /// Merges one dictionary into another. `overwrite` indicates when there is a confict, which value will take priority
    /// - Parameters:
    ///   - to: the dictionary to be merged to
    ///   - from: the dictionary contains new data
    ///   - overwrite: true if the from dictionary take priority
    static func merging(to: [String: Any?], from: [String: Any?], overwrite: Bool) -> [String:Any] {
        // overwrite all matching key value pairs with new values, and recursively handle nested dictionaries
        let combinedDictionary = combining(to: to, from: from, overwrite: overwrite)
        // handle the array wild card modification
        let mergedDictionary = handleArrayWildCard(dict: combinedDictionary, overwrite: overwrite)
        // remove nil from the dict
        return mergedDictionary.compactMapValues { $0 }
    }
    
    static func combining(to: [String: Any?], from: [String: Any?], overwrite: Bool) -> [String:Any?] {
        // First, overwrite all matching key value pairs with new values, and recursively handle nested dictionaries
        return to.merging(from, uniquingKeysWith: { (old, new) in
            if let newDict = new as? [String: Any?], let oldDict = old as? [String: Any?]  {
                // merge inner dictionary
                return merging(to:oldDict, from: newDict, overwrite: overwrite)
            } else if let newArray = new as? [Any], let oldArray = old as? [Any] {
                //TODO: currently it just combines the two arrays, the behavior is different with v5
                // merge array
                return oldArray + newArray
            }
            return overwrite ?  new : old
        })
    }
    
    static func handleArrayWildCard(dict: [String: Any?], overwrite:Bool) -> [String: Any?] {
        var dict = dict
        for (k, v) in dict {
            
            // check for the unique SUFFIX_FOR_OBJECT
            guard let range = k.range(of: SUFFIX_FOR_OBJECT) else { continue }
            
            // Remove the special key from the dict
            dict.removeValue(forKey: k)
            
            let keyWithoutSuffix: String = String(k[..<range.lowerBound])
            
            // do nothing if there is no targeted array
            guard let arrOfReceivers: [Any?] = dict[keyWithoutSuffix] as? [Any?] else { continue }
            
            // do nothing if the attachData is not a dictionary
            guard let attachData = v as? [String: Any?] else { continue}
                        
            // attach the data to each item in the array
            let arrWithAttachedData = arrOfReceivers.map { item -> Any? in
                // check if the item is a dictionary, if so, attach data to it
                guard let itemDict = item as? [String: Any?] else { return item }
                return merging(to: itemDict, from: attachData, overwrite: overwrite)
            }
            
            dict[keyWithoutSuffix] = arrWithAttachedData
              
        }
        return dict
    }
    
}
