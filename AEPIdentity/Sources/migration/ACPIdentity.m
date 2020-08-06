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

#import <Foundation/Foundation.h>
#import "ACPIdentity.h"

@implementation ACPIdentity

#pragma mark - Identity

+ (nonnull NSString*) extensionVersion {
    return @"";
}

+ (void) registerExtension {
    
}

+ (void) appendToUrl: (nullable NSURL*) baseUrl withCallback: (nullable void (^) (NSURL* __nullable urlWithVisitorData)) callback {

}

+ (void) appendToUrl: (NSURL*) baseUrl withCompletionHandler: (void (^) (NSURL* _Nullable, NSError* _Nullable)) completionHandler {
}

+ (void) getIdentifiers: (nonnull void (^) (NSArray<ACPMobileVisitorId*>* __nullable visitorIDs)) callback {

}

+ (void) getIdentifiersWithCompletionHandler: (void (^) (NSArray<ACPMobileVisitorId*>* _Nullable, NSError* _Nullable)) completionHandler {

}

+ (void) getExperienceCloudId: (nonnull void (^) (NSString* __nullable experienceCloudId)) callback {

}

+ (void) getExperienceCloudIdWithCompletionHandler: (void (^) (NSString* _Nullable, NSError* _Nullable)) completionHandler {

}

+ (void) syncIdentifier: (nonnull NSString*) identifierType
    identifier: (nonnull NSString*) identifier
         authentication: (ACPMobileVisitorAuthenticationState) authenticationState {
}

+ (void) syncIdentifiers: (nullable NSDictionary*) identifiers {

}

+ (void) syncIdentifiers: (nullable NSDictionary*) identifiers authentication: (ACPMobileVisitorAuthenticationState) authenticationState {

}

+ (void) getUrlVariables: (nonnull void (^) (NSString* __nullable urlVariables)) callback {

}

+ (void) getUrlVariablesWithCompletionHandler: (void (^) (NSString* _Nullable, NSError* _Nullable)) completionHandler {

}

@end
