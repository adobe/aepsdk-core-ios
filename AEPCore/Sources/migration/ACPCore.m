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

#import <AEPCore/AEPCore-Swift.h>
#import "ACPCore.h"
#import "AEPEvent+ACPCore.h"
#import "NSError+AEPError.h"
#import "AEPLogLevelConverter.h"
#import "AEPPrivacyStatusConverter.h"
#import "AEPWrapperTypeConverter.h"

#pragma mark - ACPCore Implementation

static NSMutableArray *_pendingExtensions;

@implementation ACPCore

#pragma mark - Configuration

+ (void)registerExtension:(id<AEPExtension> _Nonnull) extension {
    if (!_pendingExtensions) {
        _pendingExtensions = [NSMutableArray array];
    }
    
    [_pendingExtensions addObject:extension];
}

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
    [AEPCore getSdkIdentities:^(NSString * _Nullable content, enum AEPError error) {
        callback(content, [NSError errorFromAEPError:error]);
    }];
}

+ (void) getPrivacyStatus: (nonnull void (^) (ACPMobilePrivacyStatus status)) callback {
    [AEPCore getPrivacyStatus:^(enum AEPPrivacyStatus status) {
        callback([AEPPrivacyStatusConverter convertToACPPrivacyStatus:status]);
    }];
}

+ (void) getPrivacyStatusWithCompletionHandler: (nonnull void (^) (ACPMobilePrivacyStatus status, NSError* _Nullable error)) callback {
    [AEPCore getPrivacyStatus:^(enum AEPPrivacyStatus status) {
        callback([AEPPrivacyStatusConverter convertToACPPrivacyStatus:status], nil);
    }];
}

+ (nonnull NSString*) extensionVersion {
    return [AEPCore extensionVersion];
}

+ (void) setAppGroup: (nullable NSString*) appGroup {
    [AEPCore setAppGroup:appGroup];
}

+ (void) setLogLevel: (ACPMobileLogLevel) logLevel {
    [AEPCore setLogLevel:[AEPLogLevelConverter convertToAEPLogLevel:logLevel]];
}

+ (void) setPrivacyStatus: (ACPMobilePrivacyStatus) status {
    [AEPCore setPrivacy:[AEPPrivacyStatusConverter convertToAEPPrivacyStatus:status]];
}

+ (void) updateConfiguration: (NSDictionary* __nullable) config {
    [AEPCore updateConfiguration:config];
}

#pragma mark - Extensions

+ (BOOL) registerExtension: (nonnull Class) extensionClass
                     error: (NSError* _Nullable* _Nullable) error {
    // TODO
    return false;
}

+ (void) start: (nullable void (^) (void)) callback {
    [AEPCore registerExtensions:_pendingExtensions completion:^{
        [_pendingExtensions removeAllObjects];
    }];
}

#pragma mark - Generic Methods
+ (void) collectPii: (nonnull NSDictionary<NSString*, NSString*>*) data {
    // TODO
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
    AEPEvent *convertedEvent = [[AEPEvent alloc] initWithACPEvent:event];
    [AEPCore dispatch:convertedEvent];
    return YES;
}

+ (BOOL) dispatchEventWithResponseCallback: (nonnull ACPExtensionEvent*) requestEvent
                          responseCallback: (nonnull void (^) (ACPExtensionEvent* _Nonnull responseEvent)) responseCallback
                                     error: (NSError* _Nullable* _Nullable) error {
    
    AEPEvent *convertedEvent = [[AEPEvent alloc] initWithACPEvent:requestEvent];
    [AEPCore dispatch:convertedEvent responseCallback:^(AEPEvent * _Nullable responseEvent) {
        ACPExtensionEvent *convertedResponseEvent = [[ACPExtensionEvent alloc] initWithAEPEvent:responseEvent];
        responseCallback(convertedResponseEvent);
    }];
    
    return YES;
}

+ (BOOL) dispatchResponseEvent: (nonnull ACPExtensionEvent*) responseEvent
                  requestEvent: (nonnull ACPExtensionEvent*) requestEvent
                         error: (NSError* _Nullable* _Nullable) error {
    // TODO
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
    return [AEPLogLevelConverter convertToACPLogLevel:[AEPLog logFilter]];
}

+ (void) log: (ACPMobileLogLevel) logLevel tag: (nonnull NSString*) tag message: (nonnull NSString*) message {
    switch (logLevel) {
        case ACPMobileLogLevelVerbose:
            [AEPLog traceWithLabel:tag message:message];
            break;
        case ACPMobileLogLevelDebug:
            [AEPLog debugWithLabel:tag message:message];
            break;
        case ACPMobileLogLevelWarning:
            [AEPLog warningWithLabel:tag message:message];
            break;
        case ACPMobileLogLevelError:
            [AEPLog errorWithLabel:tag message:message];
            break;
        default:
            break;
    }
}

#pragma mark - Rules Engine

+ (void) downloadRules {
    // TODO
}

#pragma mark - Wrapper Support

+ (void) setWrapperType: (ACPMobileWrapperType) wrapperType {
    [AEPCore setWrapperType:[AEPWrapperTypeConverter covertToAEPWrapperType:wrapperType]];
}

@end
