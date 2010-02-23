#import <Foundation/Foundation.h>


/* RhpChecker
 Model class that connects to the Red Hot Pawn website to check the number
 of games waiting for the logged in player. The login session is taken from
 the system cookie store (NSCookieStorage). The user can login in Safari to
 effect a login. */

// status codes
#define RHPCHECKER_OK 0						
#define RHPCHECKER_DEFAULT 1000				// default or generic error
#define RHPCHECKER_COOKIE_PROBLEM 1001		// no session cookie found in cookie store
#define RHPCHECKER_CONNECTION_PROBLEM 1002  // problem connecting to site
#define RHPCHECKER_RESPONSE_PROBLEM 1003	// problem with response the site gave
#define RHPCHECKER_NEVER_CHECKED 1004		// not check attempt has yet been made
#define RHPCHECKER_OFFLINE 1005				// network connection offline
#define RHPCHECKER_NO_PERMISSION 1006		// no permission to use cookie

// protocol for completion notifications
@protocol RhpCheckerDelegate
- (void)rhpCheckerWillCheck;
- (void)rhpCheckerDidCheck;
@end

@interface RhpChecker : NSObject {
	/* Result of most recent check. Status codes RHPCHECKER_xxx defined above. */
	int status;
	
	// the number of games waiting (valid only if status is OK)
	int gamesWaiting;

	// the logged in player name (valid only if status is OK)
	NSString *playerName;
	
	// URL request for query service (to be cached)
	NSURLRequest *cachedRequest;
	
	// the query service url
	NSURL *siteQueryUrl;
	
	// url to use when visiting site
	NSURL *siteVisitUrl;
	NSURL *siteLoginUrl;
	
	// the session cookies required for login
	NSSet *siteCookieNames;
	
	// delegate for completion callback
	NSObject <RhpCheckerDelegate> *delegate;
	
	// the received data
	NSMutableData *data;
	
	// has permission to use cookie
	BOOL permission;
}

@property NSObject <RhpCheckerDelegate> *delegate;
@property BOOL permission;
@property (readonly) int status;
@property (readonly) int gamesWaiting;
@property (readonly) NSString *playerName;
@property (readonly) NSURL *siteVisitUrl;
@property (readonly) NSURL *siteLoginUrl;

/* Attempt to get the number of games waiting from the site.
 Always calls the "will check" and "did check" delegate methods.
 Check status to see if it was successful.
 Not thread safe: only one check allowed at a time. */
- (void)check;

@end

