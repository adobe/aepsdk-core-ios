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

#import <Foundation/Foundation.h>
#if __has_include("AEPIdentity-Swift.h")
    #import "AEPIdentity-Swift.h"
#else
    #import <AEPIdentity/AEPIdentity-Swift.h>
#endif
#import "ACPIdentity.h"
#import "AEPIdentityTypeBridge.h"
#import "NSError+AEPError.h"

@implementation ACPIdentity

#pragma mark - Identity

+ (nonnull NSString*) extensionVersion {
    return [AEPIdentity extensionVersion];
}

+ (void) registerExtension {
    [ACPCore registerExtension:[AEPIdentity class] error:nil];
}

+ (void) appendToUrl: (nullable NSURL*) baseUrl withCallback: (nullable void (^) (NSURL* __nullable urlWithVisitorData)) callback {
    [AEPIdentity appendToUrl:baseUrl completion:^(NSURL * _Nullable url, enum AEPError error) {
        callback(url);
    }];
}

+ (void) appendToUrl: (NSURL*) baseUrl withCompletionHandler: (void (^) (NSURL* _Nullable, NSError* _Nullable)) completionHandler {
    [AEPIdentity appendToUrl:baseUrl completion:^(NSURL * _Nullable url, enum AEPError error) {
        completionHandler(url, [NSError errorFromAEPError:error]);
    }];
}

+ (void) getIdentifiers: (nonnull void (^) (NSArray<ACPMobileVisitorId*>* __nullable visitorIDs)) callback {
    [AEPIdentity getIdentifiers:^(NSArray<id<AEPIdentifiable>> * _Nullable visitorIDs, enum AEPError error) {
       // TODO
    }];
}

+ (void) getIdentifiersWithCompletionHandler: (void (^) (NSArray<ACPMobileVisitorId*>* _Nullable, NSError* _Nullable)) completionHandler {
    [AEPIdentity getIdentifiers:^(NSArray<id<AEPIdentifiable>> * _Nullable visitorIDs, enum AEPError error) {
       // TODO
    }];
}

+ (void) getExperienceCloudId: (nonnull void (^) (NSString* __nullable experienceCloudId)) callback {
    [AEPIdentity getExperienceCloudId:^(NSString * _Nullable experienceCloudId) {
        callback(experienceCloudId);
    }];
}

+ (void) getExperienceCloudIdWithCompletionHandler: (void (^) (NSString* _Nullable, NSError* _Nullable)) completionHandler {
    [AEPIdentity getExperienceCloudId:^(NSString * _Nullable experienceCloudId) {
        completionHandler(experienceCloudId, nil);
    }];
}

+ (void) syncIdentifier: (nonnull NSString*) identifierType
    identifier: (nonnull NSString*) identifier
         authentication: (ACPMobileVisitorAuthenticationState) authenticationState {
}

+ (void) syncIdentifiers: (nullable NSDictionary*) identifiers {
    [AEPIdentity syncIdentifiers:identifiers];
}

+ (void) syncIdentifiers: (nullable NSDictionary*) identifiers authentication: (ACPMobileVisitorAuthenticationState) authenticationState {
    [AEPIdentity syncIdentifiers:identifiers authenticationState:authenticationState];
}

+ (void) getUrlVariables: (nonnull void (^) (NSString* __nullable urlVariables)) callback {
    [AEPIdentity getUrlVariables:^(NSString * _Nullable variables, enum AEPError error) {
        callback(variables);
    }];
}

+ (void) getUrlVariablesWithCompletionHandler: (void (^) (NSString* _Nullable, NSError* _Nullable)) completionHandler {
    [AEPIdentity getUrlVariables:^(NSString * _Nullable variables, enum AEPError error) {
        completionHandler(variables, [NSError errorFromAEPError:error]);
    }];
}

@end
