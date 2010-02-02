#import <Foundation/Foundation.h>


@interface NSString (FSRef) 

+ (NSString *)stringWithFSRef:(const FSRef *)aFSRef;
- (BOOL)getFSRef:(FSRef *)aFSRef;

@end
