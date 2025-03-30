#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "MacPulse" asset catalog image resource.
static NSString * const ACImageNameMacPulse AC_SWIFT_PRIVATE = @"MacPulse";

/// The "house" asset catalog image resource.
static NSString * const ACImageNameHouse AC_SWIFT_PRIVATE = @"house";

#undef AC_SWIFT_PRIVATE
