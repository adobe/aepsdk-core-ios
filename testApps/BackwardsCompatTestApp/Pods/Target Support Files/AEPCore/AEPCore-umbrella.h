#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "AEPCore.h"
#import "ACPCore.h"
#import "ACPExtensionEvent.h"
#import "ACPMobileVisitorId.h"
#import "AEPLogLevelConverter.h"
#import "AEPPrivacyStatusConverter.h"
#import "AEPWrapperTypeConverter.h"
#import "NSError+AEPError.h"

FOUNDATION_EXPORT double AEPCoreVersionNumber;
FOUNDATION_EXPORT const unsigned char AEPCoreVersionString[];

