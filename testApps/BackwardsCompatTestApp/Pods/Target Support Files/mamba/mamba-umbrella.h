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

#import "mamba.h"
#import "MambaStringRef.h"
#import "MambaStringRefFactory.h"
#import "MambaStringRef_ConcreteNSData.h"
#import "MambaStringRef_ConcreteNSString.h"
#import "MambaStringRef_ConcreteUnownedBytes.h"
#import "RapidParserMasterParseArray.h"
#import "parseHLS.h"
#import "RapidParser.h"
#import "RapidParserCallback.h"
#import "RapidParserDebug.h"
#import "RapidParserError.h"
#import "RapidParserLineState.h"
#import "RapidParserNewTagCallbacks.h"
#import "RapidParserState.h"
#import "RapidParserStateHandlers.h"
#import "StaticMemoryStorage.h"
#import "CMTimeMakeFromString.h"

FOUNDATION_EXPORT double mambaVersionNumber;
FOUNDATION_EXPORT const unsigned char mambaVersionString[];

