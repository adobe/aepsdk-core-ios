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

#import "AEPLogLevelConverter.h"

@implementation AEPLogLevelConverter

+ (AEPLogLevel)convertToAEPLogLevel: (ACPMobileLogLevel) logLevel {
    switch (logLevel) {
        case ACPMobileLogLevelVerbose:
            return AEPLogLevelTrace;
            break;
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
        case AEPLogLevelTrace:
            return ACPMobileLogLevelVerbose;
            break;
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
