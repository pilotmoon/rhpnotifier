#import "RhpChecker.h"
#import "NSHTTPCookieStorage+FilterNames.h"

@implementation RhpChecker

@synthesize gamesWaiting;
@synthesize playerName;
@synthesize status;
@synthesize siteVisitUrl;
@synthesize delegate;

- (id)init
{
	NSLog(@"RhpChecker init called");
	
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
- (void)clearRequest
{
	urlRequest=nil;
}

/* Return the cached session cookies if we have them. Otherwise, try load them into the cache
 and return them, or nil if they are not available. */
- (NSURLRequest *)cachedRequest
{
	// get the login cookies
	if(urlRequest==nil) {
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
			urlRequest=req;
		}
	}
	
	return urlRequest;
}

- (void)check
{
	status=RHPCHECKER_DEFAULT;
	
	[delegate performSelectorOnMainThread:@selector(rhpCheckerWillCheck)
							   withObject:nil waitUntilDone:NO];

	do {
		// get the request
		NSURLRequest *req=[self cachedRequest];
		if(req==nil) {
			status=RHPCHECKER_COOKIE_PROBLEM;
			break;
		}
	
		// run URL request
		NSHTTPURLResponse *response=nil;
		NSError *error=nil;
		NSData *data=[NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
		
		// check result
		if (!data) {
			NSLog(@"NSURLConnection sendSynchronousRequest failed. Error: %@", error);
			status=RHPCHECKER_CONNECTION_PROBLEM;
			break;
		}
		
		// check http status code
		if([response statusCode]!=200) {
			NSLog(@"Request status code is %d.", [response statusCode]);
			status=RHPCHECKER_RESPONSE_PROBLEM;
			break;
		}

		// load document data into a string
		NSString * s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		NSLog(@"Document data is: %@", s);
		
		// process the xml
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
	
	// if we failed then clear the request to give the best chance next time
	if(status!=RHPCHECKER_OK) {
		[self clearRequest];
	}
	
	[delegate performSelectorOnMainThread:@selector(rhpCheckerDidCheck)
							   withObject:nil waitUntilDone:NO];
}


@end
