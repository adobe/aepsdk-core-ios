import Foundation

/// An enum type representing the possible wrapper types
@objc(AEPWrapperType) public enum WrapperType: Int, RawRepresentable {
    case none
    case reactNative
    case flutter
    case cordova
    case unity
    case xamarin
    
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
}
