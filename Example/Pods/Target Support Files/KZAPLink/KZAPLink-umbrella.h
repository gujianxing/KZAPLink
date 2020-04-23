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

#import "KZAPLinkManager.h"
#import "MXQLinkMacros.h"
#import "MXQLinkSSIDHelper.h"
#import "MXQLinkTCPSocketServer.h"

FOUNDATION_EXPORT double KZAPLinkVersionNumber;
FOUNDATION_EXPORT const unsigned char KZAPLinkVersionString[];

