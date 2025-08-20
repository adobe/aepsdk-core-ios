//
// Copyright 2023 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import Foundation

struct ClassFinder {
    
    static func classConformsToProtocol(_ cls: AnyClass?, `protocol`: Protocol) -> Bool {
        var currentClass: AnyClass? = cls
        while let someClass = currentClass {
            if class_conformsToProtocol(someClass, `protocol`) { return true }
            currentClass = class_getSuperclass(someClass)
        }
        return false
    }
    
    static func classes(conformToProtocol `protocol`: Protocol) -> [AnyClass] {
        var classCount: UInt32 = 0
        guard let classList = objc_copyClassList(&classCount) else { return [] }
        defer { free(UnsafeMutableRawPointer(classList)) }
        
        guard classCount > 0 else { return [] }
        
        let classes = UnsafeBufferPointer(start: classList, count: Int(classCount))
        let filteredClasses = classes.filter { classConformsToProtocol($0, protocol: `protocol`) }        
        return filteredClasses
    }
}
