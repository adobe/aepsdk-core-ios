//
//  Dictionary+MergeOverwrite.swift
//  AEPServices
//
//  Created by Christopher Hoffman on 7/23/20.
//  Copyright © 2020 Adobe. All rights reserved.
//

import Foundation

extension Dictionary where Key == String, Value == Any {
    private static var SUFFIX_FOR_OBJECT = "[*]"
    ///
    /// Merges the new dictionary into this Dictionary, overwriting matching key value pairs from the new dictionary
    /// - Parameter new: The new Dictionary whose key value pairs
    mutating func mergeOverwrite(new: [String: Any]) {
       // First, overwrite all matching key value pairs with new values
       self.merge(new, uniquingKeysWith: { (_, new) in new })
       // Secondly, now we must check for the unique SUFFIX_FOR_OBJECT in the key to replace the internal collection
        for k in self.keys where k.range(of: Dictionary.SUFFIX_FOR_OBJECT) != nil {
            guard let range = k.range(of: Dictionary.SUFFIX_FOR_OBJECT) else { continue }
            let keyWithoutSuffix: String = String(k[..<range.lowerBound])
            // The KV exists without the suffix, so we must attach the data to each item in the Array
            if self[keyWithoutSuffix] != nil {
                // The array of items which will receive the attach data payload
                if let arrOfReceivers: [Any] = self[keyWithoutSuffix] as? [Any] {
                    let arrWithAttachedData = arrOfReceivers.map { item -> Any in
                        // check if the item is a dictionary, if so, attach data to it
                        if let itemDict = item as? [String: Any] {
                            if let attachData = self[k] as? [String: Any] {
                                return itemDict.merging(attachData, uniquingKeysWith: { (_, new) in new })
                            } else {
                                return item
                            }
                        } else {
                            return item
                        }
                    }
                    
                    self[keyWithoutSuffix] = arrWithAttachedData
                    // Remove the attach data from the merged dict
                    self.removeValue(forKey: k)
                }
            }
        }
    }
}
