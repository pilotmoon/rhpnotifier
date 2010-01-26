#import <Cocoa/Cocoa.h>
#import "RhpChecker.h"

@interface AppController : NSObject {
	// YES if currently idle, NO if checking
	BOOL ready;
	
	// the status text to display
	NSString *statusLine;
	
	// the text to display on the "go to site" link
	NSString *resultLine;
	
	// the login status text
	NSString *loginLine;
	
	// status bar item
	NSStatusItem *statusItem;
	
	// the RHP checker object
	RhpChecker *rhpChecker;

	// how long to wait between checks
	NSTimeInterval interval;
	
	// last check time (time finished checking)
	NSDate *lct;
	
	NSTimer *timer;
	
	// status menu object
	IBOutlet NSMenu *statusMenu;
}

@property BOOL ready;
@property (readonly) BOOL pulldown;
@property (copy) NSString *statusLine;
@property (copy) NSString *resultLine;
@property (copy) NSString *loginLine;

// the available UI actions
- (IBAction)goToSite:(id)sender;

// UI update methods
- (void)updateResult;
- (void)updateStatus;

- (void)timerRoutine:(NSTimer *)timer;
- (void)willRun;
- (void)didRun;

// rhpchecker delegate method
- (void)rhpCheckComplete;

@end
