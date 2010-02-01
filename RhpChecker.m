#import "RhpChecker.h"
#import "NSHTTPCookieStorage+FilterNames.h"
#include "debug.h"

@implementation RhpChecker

@synthesize gamesWaiting;
@synthesize playerName;
@synthesize status;
@synthesize siteVisitUrl;
@synthesize delegate;

- (id)init
{
	DLog(@"RhpChecker init called");
	
	// set default
	gamesWaiting=0;
	playerName=nil;
	status=RHPCHECKER_NEVER_CHECKED;
	
	// site specific parameters
	siteQueryUrl=[NSURL URLWithString:@"http://www.redhotpawn.com/xml/simple/gameswaitingcount_xml.php"];
	siteVisitUrl=[NSURL URLWithString:@"http://www.redhotpawn.com/core/gameserve.php"];
	siteCookieNames=[NSSet setWithObjects:@"rhp_cookieid", @"rhp_uid", nil];
	
	return self;
}


/* Clear the url request so it will be created again on the next check */
- (void)clearCachedRequest
{
	cachedRequest=nil;
}

- (void)clearData
{
	data = [NSMutableData dataWithLength:0];
}

/* Return the cached request if we have one. Otherwise, create one. */
- (NSURLRequest *)cachedRequest
{
	// get the login cookies
	if(cachedRequest==nil) {
		NSLog(@"Generating URL request");
		
		// get cookies
		NSArray *cookies=[[NSHTTPCookieStorage sharedHTTPCookieStorage]
						  cookiesForURL:siteQueryUrl withNames:siteCookieNames];
		if([cookies count]!=[siteCookieNames count])
		{
			NSLog(@"Session cookies not found for site %@", siteQueryUrl);
		}
		else
		{
			// set up URL request
			NSMutableURLRequest *req=[NSMutableURLRequest requestWithURL:siteQueryUrl];
			[req setAllHTTPHeaderFields:[NSHTTPCookie requestHeaderFieldsWithCookies:cookies]];
			cachedRequest=req;
		}
	}
	
	return cachedRequest;
}

- (void)check
{
	status=RHPCHECKER_DEFAULT;
	[delegate rhpCheckerWillCheck];

	NSURLRequest *req=[self cachedRequest];
	if(req==nil) {
		status=RHPCHECKER_COOKIE_PROBLEM;
	}
	else {
		[self clearData];
		
		NSURLConnection *conn=[[NSURLConnection alloc] initWithRequest:req
															  delegate:self
													  startImmediately:NO];
		/* must schedule in "common modes" so it will work regardless
		 of whether the a menu is open or not */
		[conn scheduleInRunLoop:[NSRunLoop currentRunLoop]
						forMode:NSRunLoopCommonModes];
		[conn start];
	}
}


- (void)washup
{
	// if we failed then clear the cached connection, assume it is bad
	if(status!=RHPCHECKER_OK) {
		[self clearCachedRequest];
	}
	[delegate rhpCheckerDidCheck];
}


// connection failed
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	NSLog(@"NSURLConnection sendSynchronousRequest failed. Error: %@", error);
	if ([error domain]==NSURLErrorDomain && [error code]==NSURLErrorNotConnectedToInternet) {
		status = RHPCHECKER_OFFLINE;
	}
	else {
		status = RHPCHECKER_CONNECTION_PROBLEM;
	}
	
	[self washup];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
	NSLog(@"received url response");

	// if it's not 200 just dump everything
	if([response statusCode]!=200) {
		NSLog(@"Request status code is %d.", [response statusCode]);
		status=RHPCHECKER_RESPONSE_PROBLEM;
		[connection cancel];
		[self washup];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)theData
{
	NSLog(@"received data");
	[data appendData:theData];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	do {
	
#ifdef DEBUG
		// load document data into a string
		NSString * s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		NSLog(@"Document data is: %@", s);
#endif		
		// process the xml
		NSError *error;
		NSXMLDocument *xml=[[NSXMLDocument alloc] initWithData:data options:0 error:&error];
		if(xml==nil) {
			NSLog(@"XML processing failed. Error: %@", error);
			status=RHPCHECKER_RESPONSE_PROBLEM;
			break;
		}
		
		// get the player name (but don't fail if can't get it)
		NSArray *nodes = [xml nodesForXPath:@"./mygames/@name" error:&error];
		playerName=[nodes count] == 1 ? [[nodes objectAtIndex:0] stringValue]: nil;
		
		// get the number of games waiting
		nodes = [xml nodesForXPath:@"./mygames/waiting" error:&error];
		if ([nodes count] != 1 ) {
			NSLog(@"Document not contain games waiting info. Error: %@", error);
			status=RHPCHECKER_RESPONSE_PROBLEM;
			break;
		}
		
		// there is one such node
		gamesWaiting=[[[nodes objectAtIndex:0] stringValue] intValue];
		NSLog(@"Found %d games waiting",gamesWaiting);
		status=RHPCHECKER_OK;

	} while(NO);
	
	[self washup];
}


@end
