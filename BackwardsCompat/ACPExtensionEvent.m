/*
Copyright 2018 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/

#import <Foundation/Foundation.h>
#import <AEPCore/AEPCore-Swift.h>
#import "ACPExtensionEvent.h"

@implementation ACPExtensionEvent {
    AEPEvent *event_;
}

- (nonnull id) initWithAEPEvent: (nonnull AEPEvent *) event {
    self = [super init];
    event_ = event;
    return self;
}

+ (nullable instancetype) extensionEventWithName: (nonnull NSString*) name
                                            type: (nonnull NSString*) type
                                          source: (nonnull NSString*) source
                                            data: (nullable NSDictionary*) data
                                           error: (NSError* _Nullable* _Nullable) error {
    AEPEvent *event = [[AEPEvent alloc] initWithName:name type:type source:source data:data];
    return [[ACPExtensionEvent alloc] initWithAEPEvent:event];
}

- (nonnull NSString*) eventName {
    return [event_ name];
}

- (nonnull NSString*) eventType {
    return [event_ type];
}

- (nonnull NSString*) eventSource {
    return [event_ source];
}

- (nullable NSDictionary*) eventData {
    return [event_ data];
}

- (nonnull NSString*) eventUniqueIdentifier {
    return @"";
}

- (long) eventTimestamp {
    return -1;
}

- (int) eventNumber {
    return -1;
}

@end

