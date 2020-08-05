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

#import "AEPWrapperTypeConverter.h"

@implementation AEPWrapperTypeConverter

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

@end
