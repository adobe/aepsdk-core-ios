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

/// An enum type representing the possible wrapper types
@objc(AEPWrapperType) public enum WrapperType: Int, RawRepresentable {
    case none = 0
    case reactNative = 1
    case flutter = 2
    case cordova = 3
    case unity = 4
    case xamarin = 5

    public typealias RawValue = String

    public var rawValue: RawValue {
        switch self {
        case .none:
            return CoreConstants.WrapperType.NONE
        case .reactNative:
            return CoreConstants.WrapperType.REACT_NATIVE
        case .flutter:
            return CoreConstants.WrapperType.FLUTTER
        case .cordova:
            return CoreConstants.WrapperType.CORDOVA
        case .unity:
            return CoreConstants.WrapperType.UNITY
        case .xamarin:
            return CoreConstants.WrapperType.XAMARIN
        }
    }

    public init?(rawValue: RawValue) {
        switch rawValue {
        case CoreConstants.WrapperType.NONE:
            self = .none
        case CoreConstants.WrapperType.REACT_NATIVE:
            self = .reactNative
        case CoreConstants.WrapperType.FLUTTER:
            self = .flutter
        case CoreConstants.WrapperType.CORDOVA:
            self = .cordova
        case CoreConstants.WrapperType.UNITY:
            self = .unity
        case CoreConstants.WrapperType.XAMARIN:
            self = .xamarin
        default:
            self = .none
        }
    }

    var friendlyName: String {
        switch self {
        case .none:
            return CoreConstants.WrapperName.NONE
        case .reactNative:
            return CoreConstants.WrapperName.REACT_NATIVE
        case .flutter:
            return CoreConstants.WrapperName.FLUTTER
        case .cordova:
            return CoreConstants.WrapperName.CORDOVA
        case .unity:
            return CoreConstants.WrapperName.UNITY
        case .xamarin:
            return CoreConstants.WrapperName.XAMARIN
        }
    }
}
