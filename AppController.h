#import <Cocoa/Cocoa.h>
#import "RhpChecker.h"
#import "BackgroundTaskRunner.h"

@interface AppController : NSObject <NSMenuDelegate> {
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
	
	// helper object for running in background
	BackgroundTaskRunner *taskRunner;

	// how long to wait between checks
	NSTimeInterval delay;
	
	// status menu object
	IBOutlet NSMenu *statusMenu;
}

@property BOOL ready;
@property (readonly) BOOL pulldown;
@property (copy) NSString *statusLine;
@property (copy) NSString *resultLine;
@property (copy) NSString *loginLine;

// the available UI actions
- (IBAction)checkNow:(id)sender;
- (IBAction)goToSite:(id)sender;

// UI update methods
- (void)updateResult;
- (void)updateStatus;

// task scheduling methods
- (void)scheduleTask;
- (void)cancelTask;

// task runner delegate methods
- (void)task;
- (void)willRun;
- (void)didRun;

// methods for changing the delay
- (void)resetDelay;
- (void)increaseDelay;


@end
