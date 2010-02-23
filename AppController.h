#import <AppKit/AppKit.h>
#import "RhpChecker.h"

@interface AppController : NSObject <RhpCheckerDelegate> {
	// YES if currently idle, NO if checking
	BOOL ready;
	
	// whether menu items should be enabled
	BOOL menuEnabled;
	
	// the status text to display
	NSString *statusLine;
	
	// the text to display on the "go to site" link
	NSString *resultLine;
	
	// the login status text
	NSString *loginLine;

	// text to display in login window
	NSAttributedString *loginWindowText;
	
	// status bar item
	NSStatusItem *statusItem;
	
	// the RHP checker object
	RhpChecker *rhpChecker;

	// how long to wait between checks
	NSTimeInterval interval;
	
	// last check time (time finished checking)
	NSDate *lct;
	
	// timer, for timing :)
	NSTimer *timer;
	
	// status menu object
	IBOutlet NSMenu *statusMenu;
	
	// login window
	IBOutlet NSWindow *loginWindow;
	
	// status icons
	NSImage *statusImageBlack;
	NSImage *statusImageRed;
	NSImage *statusImageGrey;
}

@property BOOL ready;
@property (readonly) BOOL pulldown;
@property (readonly) BOOL statusOk;
@property BOOL startAtLogin;
@property BOOL menuEnabled;
@property (copy) NSString *statusLine;
@property (copy) NSString *resultLine;
@property (copy) NSString *loginLine;
@property (copy) NSAttributedString *loginWindowText;


// the available UI actions
- (IBAction)goToSite:(id)sender;
- (IBAction)openInSafari:(id)sender;
- (IBAction)about:(id)sender;
- (IBAction)checkNow:(id)sender;

// UI update methods
- (void)updateResult;
- (void)updateStatus;
- (void)updateIcon;

- (void)prepareLoginWindow;
- (void)showLoginWindow;

// timer methods
- (void)timerRoutine:(NSTimer *)timer;
- (void)schedule;
- (void)reschedule;

@end
