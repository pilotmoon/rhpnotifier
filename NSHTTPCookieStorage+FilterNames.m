#import "NSHTTPCookieStorage+FilterNames.h"


@implementation NSHTTPCookieStorage (FilterNames)

- (NSArray *)cookiesForURL:(NSURL *)url withNames:(NSSet *)names
{	
	// empty dictionary to store found cookies in
	NSMutableArray *result=[NSMutableArray arrayWithCapacity:[names count]];
	
	// for each cookie that the system is storing for the url
	for(NSHTTPCookie *cookie in [self cookiesForURL:url])
	{
		// is it one of the ones we are looking for
		if([names containsObject:[cookie name]])
		{
			[result addObject:cookie];
		}
	}
	
	// return the matching cookies
	return result;
}

@end
