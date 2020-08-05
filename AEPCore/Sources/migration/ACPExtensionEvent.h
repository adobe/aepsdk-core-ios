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

#ifndef ADOBEMOBILE_ADBEXTENSIONEVENT_H
#define ADOBEMOBILE_ADBEXTENSIONEVENT_H

#import <Foundation/Foundation.h>
@class AEPEvent;

@interface ACPExtensionEvent : NSObject {}

/// Creates a new `ACPExtensionEvent` where the underlying event is the `AEPEvent`
/// @param event the event to populate this event's data
- (nonnull id)initWithAEPEvent: (nonnull AEPEvent *) event;

/**
 * @brief Create a new broadcast event.
 *
 * Creates a new ACPExtensionEvent which may be dispatched to the Mobile SDK. An ACPExtensionEvent is heard by any listeners which are registered to
 * the same EventType and EventSource as the event.
 *
 * @param name The name of the event to be dispatched.
 * @param type The type of the event to be dispatched.
 * @param source The source of the event to be dispatched.
 * @param data (Optional) Data associated with the event. The NSDictionary passed should follow NSCoding protocol.
 * @param error (Optional) NSError** where any errors constructing the event can be reported.
 * @return a new instance of ACPExtensionEvent or nil if `data` is non-nil and is not in a valid format
 *
 * @see ACPCore::dispatchEvent:error:
 * @see ACPCore::dispatchEventWithResponseCallback:responseCallback:error:
 * @see ACPCore::dispatchResponseEvent:requestEvent:error:
 */
+ (nullable instancetype) extensionEventWithName: (nonnull NSString*) name
                                            type: (nonnull NSString*) type
                                          source: (nonnull NSString*) source
                                            data: (nullable NSDictionary*) data
                                           error: (NSError* _Nullable* _Nullable) error;

/**
 * @brief The EventData of this ACPExtensionEvent
 *
 * The optional EventData may contain any payload information required for this ACPExtensionEvent.
 */
@property(nonatomic, readonly) NSDictionary* _Nullable eventData;

/**
 * @brief The name of this ACPExtensionEvent
 *
 * The ACPExtensionEvent name is a descriptive string used for logging.
 */
@property(nonatomic, readonly) NSString* _Nonnull eventName;

/**
 * @brief The eventNumber of the original Event processed by the SDK
 *
 * The SDK assigns eventNumber to an Event prior to dispatching it.
 * eventNumber is an auto-incremented value that is stored in memory.
 */
@property(nonatomic, readonly) int eventNumber;

/**
 * @brief The EventSource of this ACPExtensionEvent
 *
 * An ACPExtensionEvent is received by listeners which register with the same EventType and EventSource as the dispatched event.
 */
@property(nonatomic, readonly) NSString* _Nonnull eventSource;

/**
 * @brief The EventType of this ACPExtensionEvent
 *
 * An ACPExtensionEvent is received by listeners which register with the same EventType and EventSource as the dispatched event.
 */
@property(nonatomic, readonly) NSString* _Nonnull eventType;

/**
 * @brief A string representation of a UUID to identify this ACPExtensionEvent
 *
 * eventUniqueIdentifier differs from eventNumber because it does not reset between sessions.
 * The value for eventUniqueIdentifier is guaranteed to always be unique.
 */
@property(nonatomic, readonly) NSString* _Nonnull eventUniqueIdentifier;

/**
 * @brief Timestamp representing the time that this event was originally processed by the SDK
 *
 * The value for eventTimestamp is representing milliseconds since the Unix epoch
 */
@property(nonatomic, readonly) long eventTimestamp;


@end

#endif /* ADOBEMOBILE_ADBEXTENSIONEVENT_H */
