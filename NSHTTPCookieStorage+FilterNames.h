#import <Foundation/Foundation.h>


@interface NSHTTPCookieStorage (FilterNames)

/* A version of cookiesForURL which returns only those cookies with names
 in a given set */
- (NSArray *)cookiesForURL:(NSURL *)url withNames:(NSSet *)names;

@end
