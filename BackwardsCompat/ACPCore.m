/*
Copyright 2017 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/


// #import obj-c classes/headers
#import <AEPCore/AEPCore-Swift.h>
#import "ACPCore.h"
#import "ACPExtension.h"
#import "ACPError.h"

#pragma mark - ACPCore Implementation
@implementation ACPCore

#pragma mark - Configuration

+ (void) configureWithAppId: (NSString* __nullable) appid {
    [AEPCore configureWithAppId:appid];
}

+ (void) configureWithFileInPath: (NSString* __nullable) filepath {
    [AEPCore configureWithFilePath:filepath];
}

+ (void) getSdkIdentities: (nullable void (^) (NSString* __nullable content)) callback {
    [AEPCore getSdkIdentities:^(NSString * _Nullable content, enum AEPError error) {
        callback(content);
    }];
}

+ (void) getSdkIdentitiesWithCompletionHandler: (nullable void (^) (NSString* __nullable content, NSError* _Nullable error)) callback {

}

+ (void) getPrivacyStatus: (nonnull void (^) (ACPMobilePrivacyStatus status)) callback {
    [AEPCore getPrivacyStatus:^(enum AEPPrivacyStatus status) {
        callback([self convertToACPPrivacyStatus:status]);
    }];
}

+ (void) getPrivacyStatusWithCompletionHandler: (nonnull void (^) (ACPMobilePrivacyStatus status, NSError* _Nullable error)) callback {
    [AEPCore getPrivacyStatus:^(enum AEPPrivacyStatus status) {
        callback([self convertToACPPrivacyStatus:status], nil);
    }];
}


+ (nonnull NSString*) extensionVersion {
    return [AEPCore extensionVersion];
}

+ (void) setAppGroup: (nullable NSString*) appGroup {
    [AEPCore setAppGroup:appGroup];
}

+ (void) setLogLevel: (ACPMobileLogLevel) logLevel {
    [AEPCore setLogLevel:[self convertToAEPLogLevel:logLevel]];
}

+ (void) setPrivacyStatus: (ACPMobilePrivacyStatus) status {
    [AEPCore setPrivacy:[self convertToAEPPrivacyStatus:status]];
}

+ (void) updateConfiguration: (NSDictionary* __nullable) config {
    [AEPCore updateConfiguration:config];
}

#pragma mark - Extensions

+ (BOOL) registerExtension: (nonnull Class) extensionClass
                     error: (NSError* _Nullable* _Nullable) error {

    return false;
}

+ (void) start: (nullable void (^) (void)) callback {
    // TODO
}

#pragma mark - Generic Methods
+ (void) collectPii: (nonnull NSDictionary<NSString*, NSString*>*) data {

}

+ (void) lifecyclePause {
    [AEPCore lifecyclePause];
}

+ (void) lifecycleStart: (nullable NSDictionary<NSString*, NSString*>*) additionalContextData {
    [AEPCore lifecycleStart:additionalContextData];
}

+ (void) setAdvertisingIdentifier: (nullable NSString*) adId {
    [AEPCore setAdvertisingIdentifier:adId];
}

#if !TARGET_OS_WATCH
+ (void) registerURLHandler: (nonnull BOOL (^) (NSString* __nullable url)) callback {
    // TODO
}
#endif

+ (void) setPushIdentifier: (nullable NSData*) deviceToken {
    [AEPCore setPushIdentifier:deviceToken];
}

+ (void) trackAction: (nullable NSString*) action data: (nullable NSDictionary<NSString*, NSString*>*) data {
    // TODO
}

+ (void) trackState: (nullable NSString*) state data: (nullable NSDictionary<NSString*, NSString*>*) data {
    // TODO
}

+ (BOOL) dispatchEvent: (nonnull ACPExtensionEvent*) event
                 error: (NSError* _Nullable* _Nullable) error {
    return NO;
}

+ (BOOL) dispatchEventWithResponseCallback: (nonnull ACPExtensionEvent*) requestEvent
                          responseCallback: (nonnull void (^) (ACPExtensionEvent* _Nonnull responseEvent)) responseCallback
                                     error: (NSError* _Nullable* _Nullable) error {
    return NO;
}

+ (BOOL) dispatchResponseEvent: (nonnull ACPExtensionEvent*) responseEvent
                  requestEvent: (nonnull ACPExtensionEvent*) requestEvent
                         error: (NSError* _Nullable* _Nullable) error {
    return NO;
}

+ (void) collectLaunchInfo: (nonnull NSDictionary*) userInfo {
    // TODO
}

+ (void) collectMessageInfo: (nonnull NSDictionary*) messageInfo {
    // TODO
}

#pragma mark - Logging Utilities

+ (ACPMobileLogLevel) logLevel {
    return [self convertToACPLogLevel:[AEPLog logFilter]];
}

+ (void) log: (ACPMobileLogLevel) logLevel tag: (nonnull NSString*) tag message: (nonnull NSString*) message {
    // TODO:
}

#pragma mark - Rules Engine

+ (void) downloadRules {
    // TODO
}

#pragma mark - Wrapper Support

+ (void) setWrapperType: (ACPMobileWrapperType) wrapperType {
    [AEPCore setWrapperType:[self covertToAEPWrapperType:wrapperType]];
}

+ (ACPMobilePrivacyStatus)convertToACPPrivacyStatus: (AEPPrivacyStatus) privacyStatus {
    switch (privacyStatus) {
        case AEPPrivacyStatusOptedIn:
            return ACPMobilePrivacyStatusOptIn;
            break;
        case AEPPrivacyStatusOptedOut:
            return ACPMobilePrivacyStatusOptOut;
            break;
        default:
            return ACPMobilePrivacyStatusUnknown;
            break;
    }
}

+ (AEPPrivacyStatus)convertToAEPPrivacyStatus: (ACPMobilePrivacyStatus) privacyStatus {
    switch (privacyStatus) {
        case ACPMobilePrivacyStatusOptIn:
            return AEPPrivacyStatusOptedIn;
            break;
        case ACPMobilePrivacyStatusOptOut:
            return AEPPrivacyStatusOptedOut;
            break;
        default:
            return AEPPrivacyStatusUnknown;
            break;
    }
}

+ (ACPMobileWrapperType)covertToACPWrapperType: (AEPWrapperType) wrapperType {
    switch (wrapperType) {
        case AEPWrapperTypeNone:
            return ACPMobileWrapperTypeNone;
            break;
        case AEPWrapperTypeReactNative:
            return ACPMobileWrapperTypeReactNative;
            break;
        case AEPWrapperTypeFlutter:
            return ACPMobileWrapperTypeFlutter;
            break;
        case AEPWrapperTypeCordova:
            return ACPMobileWrapperTypeCordova;
            break;
        case AEPWrapperTypeUnity:
            return ACPMobileWrapperTypeUnity;
            break;
        case AEPWrapperTypeXamarin:
            return ACPMobileWrapperTypeXamarin;
            break;
        default:
            return ACPMobileWrapperTypeNone;
            break;
    }
}

+ (AEPWrapperType)covertToAEPWrapperType: (ACPMobileWrapperType) wrapperType {
    switch (wrapperType) {
        case ACPMobileWrapperTypeNone:
            return AEPWrapperTypeNone;
            break;
        case ACPMobileWrapperTypeReactNative:
            return AEPWrapperTypeReactNative;
            break;
        case ACPMobileWrapperTypeFlutter:
            return AEPWrapperTypeFlutter;
            break;
        case ACPMobileWrapperTypeCordova:
            return AEPWrapperTypeCordova;
            break;
        case ACPMobileWrapperTypeUnity:
            return AEPWrapperTypeUnity;
            break;
        case ACPMobileWrapperTypeXamarin:
            return AEPWrapperTypeXamarin;
            break;
        default:
            return AEPWrapperTypeNone;
            break;
    }
}

+ (AEPLogLevel)convertToAEPLogLevel: (ACPMobileLogLevel) logLevel {
    switch (logLevel) {
        case ACPMobileLogLevelDebug:
            return AEPLogLevelDebug;
            break;
        case ACPMobileLogLevelWarning:
            return AEPLogLevelWarning;
            break;
        case ACPMobileLogLevelError:
            return AEPLogLevelError;
            break;
        default:
            return AEPLogLevelError;
            break;
    }
}

+ (ACPMobileLogLevel)convertToACPLogLevel: (AEPLogLevel) logLevel {
    switch (logLevel) {
        case AEPLogLevelDebug:
            return ACPMobileLogLevelDebug;
            break;
        case AEPLogLevelWarning:
            return ACPMobileLogLevelWarning;
            break;
        case AEPLogLevelError:
            return ACPMobileLogLevelError;
            break;
        default:
            return ACPMobileLogLevelError;
            break;
    }
}

@end
