//
//  AEPEvent+AEPEvent_ACPCore.h
//  AEPCore
//
//  Created by Nick Porter on 8/4/20.
//  Copyright © 2020 Adobe. All rights reserved.
//

#import <AEPCore/AEPCore-Swift.h>
#import "ACPExtensionEvent.h"

@interface AEPEvent (AEPEvent_ACPCore)

- (id)initWithACPEvent:(ACPExtensionEvent *) event;

@end

