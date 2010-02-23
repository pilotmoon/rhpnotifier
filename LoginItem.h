#import <Cocoa/Cocoa.h>


@interface LoginItem : NSObject

+ (BOOL) willStartAtLogin:(NSURL *)itemURL;
+ (void) setStartAtLogin:(NSURL *)itemURL enabled:(BOOL)enabled;

@end
