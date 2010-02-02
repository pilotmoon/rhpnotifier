#import <Foundation/Foundation.h>
#import "NSString+FSRef.h"

@interface NSURL (App)

- (void)openInAppWithIdentifier:(NSString *)identifier;

@end
