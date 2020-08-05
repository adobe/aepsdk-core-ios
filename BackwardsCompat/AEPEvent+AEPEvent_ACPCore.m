//
//  AEPEvent+AEPEvent_ACPCore.m
//  AEPCore
//
//  Created by Nick Porter on 8/4/20.
//  Copyright © 2020 Adobe. All rights reserved.
//

#import "AEPEvent+AEPEvent_ACPCore.h"

@implementation AEPEvent (AEPEvent_ACPCore)

- (id)initWithACPEvent:(ACPExtensionEvent *) event {
    self = [[AEPEvent alloc] initWithName:event.eventName type:event.eventType source:event.eventSource data:event.eventData];
    return self;
}

@end
