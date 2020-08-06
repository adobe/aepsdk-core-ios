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
#if __has_include("AEPSignal-Swift.h")
    #import "AEPSignal-Swift.h"
#else
    #import <AEPSignal/AEPSignal-Swift.h>
#endif
#import "ACPCore.h"
#import "ACPSignal.h"

@implementation ACPSignal

#pragma mark - Signal

+ (nonnull NSString*) extensionVersion {
    return [AEPSignal extensionVersion];
}

+ (void) registerExtension {
    [ACPCore registerExtension:[AEPSignal class] error:nil];
}

@end
