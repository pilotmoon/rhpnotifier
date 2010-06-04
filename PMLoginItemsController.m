#import "PMLoginItemsController.h"

// Login items change callback.
static void loginItemsChanged(LSSharedFileListRef listRef, void *context)
{
    PMLoginItemsController *controller = context;
	
    // Emit change notification. We can't do will/did
    // around the change but this will have to do.
    [controller willChangeValueForKey:@"startAtLogin"];
    [controller didChangeValueForKey:@"startAtLogin"];
}

// Class to encapsulate "start at login" checkbox functionality.
// Note this code requires garbage collection on.
@implementation PMLoginItemsController

// Get reference to login items list and add observer for changes.
- (id)init
{
	if(!(self = [super init])) return nil;
	loginItems = (LSSharedFileListRef)CFMakeCollectable(LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL));
	NSAssert(loginItems, nil);
	if (loginItems) {
		// Add an observer so we can update the UI if changed externally.
		LSSharedFileListAddObserver(loginItems,
									CFRunLoopGetMain(),
									kCFRunLoopCommonModes,
									loginItemsChanged,
									self);
		NSLog(@"loginitem init ok");
	}
	
	// Add cleanup routine for application termination.
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(cleanup)
												 name:NSApplicationWillTerminateNotification
											   object:nil];
	return self;
}
 
// Remove login items list observer.
- (void)cleanup
{
	if (loginItems) {
		NSLog(@"loginitem cleanup");
		LSSharedFileListRemoveObserver(loginItems,
									   CFRunLoopGetMain(),
									   kCFRunLoopCommonModes,
									   loginItemsChanged,
									   self);
	}
}

// Check if app is in login items.
- (BOOL)startAtLogin
{
	Boolean foundIt=false;
	if (loginItems) {
		NSURL *itemURL=[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
		UInt32 seed = 0U;
		NSArray *currentLoginItems = [NSMakeCollectable(LSSharedFileListCopySnapshot(loginItems, &seed)) autorelease];
		for (id itemObject in currentLoginItems) {
			LSSharedFileListItemRef item = (LSSharedFileListItemRef)itemObject;
			
			UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
			CFURLRef URL = NULL;
			OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, /*outRef*/ NULL);
			if (err == noErr) {
				foundIt = CFEqual(URL, itemURL);
				CFRelease(URL);
				
				if (foundIt)
					break;
			}
		}
	}
	return (BOOL)foundIt;
}

// Add/remove app to/from login items.
- (void)setStartAtLogin:(BOOL)enabled
{
	if (loginItems) {
		[self willChangeValueForKey:@"startAtLogin"];
		NSURL *itemURL=[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
		
		LSSharedFileListItemRef existingItem = NULL;

		UInt32 seed = 0U;
		NSArray *currentLoginItems = [NSMakeCollectable(LSSharedFileListCopySnapshot(loginItems, &seed)) autorelease];
		for (id itemObject in currentLoginItems) {
			LSSharedFileListItemRef item = (LSSharedFileListItemRef)itemObject;
			
			UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
			CFURLRef URL = NULL;
			OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, /*outRef*/ NULL);
			if (err == noErr) {
				Boolean foundIt = CFEqual(URL, itemURL);
				CFRelease(URL);
				
				if (foundIt) {
					existingItem = item;
					break;
				}
			}
		}
		
		if (enabled && (existingItem == NULL)) {
			LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemBeforeFirst,
										  NULL, NULL, (CFURLRef)itemURL, NULL, NULL);
		
		} else if (!enabled && (existingItem != NULL))
			LSSharedFileListItemRemove(loginItems, existingItem);
		[self didChangeValueForKey:@"startAtLogin"];
	}
}

@end
