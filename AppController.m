#import "AppController.h"
#include "debug.h"

#define INTERVAL_RECONNECT 10
#define INTERVAL_MIN 60
#define INTERVAL_MAX 1800
#define INTERVAL_MULTIPLIER 1.2

@implementation AppController

@synthesize ready, menuEnabled;
@synthesize statusLine, resultLine, loginLine, loginWindowText;

- (BOOL)pulldown
{
	return NO;
}

- (id)init
{
	[super init];
	
	self.ready=NO;
	self.menuEnabled=YES;
	lct = [NSDate distantPast];
	interval=0;
	
	[self updateResult];
	[self updateStatus];
	
	// register for wake from sleep notification
	[[[NSWorkspace sharedWorkspace] notificationCenter]
	 addObserver:self
		selector:@selector(handleWakeFromSleep:)
			name:NSWorkspaceDidWakeNotification 
		  object:[NSWorkspace sharedWorkspace]];
	
	rhpChecker = [[RhpChecker alloc] init];
	[rhpChecker setDelegate:self];
	
	return self;
}

- (void)awakeFromNib
{
	// set up the status menu
	NSStatusBar *bar = [NSStatusBar systemStatusBar];
	statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
	[statusItem setHighlightMode:YES];	
	[statusItem setMenu:statusMenu];
	[statusMenu setDelegate:self];
	
	[self prepareLoginWindow];
	
	[self schedule];
}

- (void)prepareLoginWindow
{
	NSString *path=[[NSBundle mainBundle] pathForResource:@"LoginWindowText"
												   ofType:@"rtf"];
	self.loginWindowText = [[NSAttributedString alloc] initWithPath:path
												 documentAttributes:nil];
	[loginWindow setDelegate:self];
}

- (void)showLoginWindow
{
	NSLog(@"showing login window");
	[NSApp activateIgnoringOtherApps:YES];
	[NSApp runModalForWindow:loginWindow];
}

- (IBAction)about:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[NSApp orderFrontStandardAboutPanel:nil];
}

- (void)windowWillClose:(NSNotification *)note
{
	if ([note object]==loginWindow) {
		[NSApp stopModal];
		[self setMenuEnabled:YES];
	}
}

- (void)windowDidBecomeKey:(NSNotification *)note
{
	if ([note object]==loginWindow) {
		[self setMenuEnabled:NO];
	}
}

- (void)updateResult
{
	switch(rhpChecker.status) {
		case RHPCHECKER_OK:
			switch (rhpChecker.gamesWaiting) {
				case 0:
					self.resultLine=@"0 games waiting";
					[statusItem setTitle:@"RHP"];	
					break;
				case 1:
					self.resultLine=@"1 game waiting";
					[statusItem setTitle:@"RHP:1"];	
					break;
				default:
					self.resultLine=[NSString stringWithFormat:@"%d games waiting", rhpChecker.gamesWaiting];
					[statusItem setTitle:[NSString stringWithFormat:@"RHP:%d",rhpChecker.gamesWaiting]];			
					break;
			}
			break;
	
		case RHPCHECKER_COOKIE_PROBLEM:
			self.resultLine=@"Login...";
			[statusItem setTitle:@"RHP"];	
			break;
	
		default:
			self.resultLine=@"Go to site";
			[statusItem setTitle:@"RHP"];	
			break;
	}
	
}

- (void)updateStatus
{
	switch(rhpChecker.status)
	{
		case RHPCHECKER_OK:
			self.statusLine=@"Status: OK";
			self.loginLine=[NSString stringWithFormat:@"Logged in as %@",
							rhpChecker.playerName];
			break;
		case RHPCHECKER_NEVER_CHECKED:
			self.statusLine=@"Status: Application starting...";
			self.loginLine=@"Not logged in";
			break;
		case RHPCHECKER_COOKIE_PROBLEM:
			self.statusLine=@"Status: Cookie needed";
			self.loginLine=@"Not logged in";
			break;
		case RHPCHECKER_OFFLINE:
			self.statusLine=@"Status: Offline";
			self.loginLine=@"Not logged in";
			break;
		case RHPCHECKER_CONNECTION_PROBLEM:
			self.statusLine=@"Status: Could not connect";
			self.loginLine=@"Not logged in";
			break;
		case RHPCHECKER_RESPONSE_PROBLEM:
		default:
			self.statusLine=@"Status: Site response error";
			self.loginLine=@"Not logged in";
			break;
	}
}

- (void)rhpCheckerWillCheck
{
	self.ready=NO;
	self.statusLine=@"Status: Checking...";
	[statusMenu update];
}

- (void)rhpCheckerDidCheck
{
	NSLog(@"check complete");
	
	// update ui
	[self updateResult];
	[self updateStatus];
	
	if (rhpChecker.status == RHPCHECKER_OK) {
		if (interval < INTERVAL_MIN) {
			interval = INTERVAL_MIN;
		}
		else {
			interval*=INTERVAL_MULTIPLIER;
			if (interval > INTERVAL_MAX) {
				interval = INTERVAL_MAX;
			}		
		}
	}
	else {
		interval=INTERVAL_RECONNECT;
	}
	
	[self schedule];
	self.ready=YES;
	[statusMenu update];
}

- (void)timerRoutine:(NSTimer *)unused
{
	NSLog(@"--> timer routine fired");
	[rhpChecker check];
}

- (void)schedule
{
	NSLog(@"last checked at %@", lct);

	// schedule next check
	lct = [NSDate date];
	timer = [NSTimer timerWithTimeInterval:interval target:self 
								  selector:@selector(timerRoutine:)
								  userInfo:nil
								   repeats:NO];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
	
	NSLog(@"new interval is %f", interval);
	NSLog(@"timer scheduled for %@", [timer fireDate]);	
}

- (void)reschedule
{
	if ([timer isValid]) {
		NSLog(@"rescehduling fire date from %@", [timer fireDate]);
		[timer setFireDate:[[NSDate alloc] initWithTimeInterval:interval 
													  sinceDate:lct]];
		NSLog(@"                         to %@", [timer fireDate]);
	}
}

- (void)checkSoon
{
	interval = [rhpChecker status] == RHPCHECKER_OK ? INTERVAL_MIN : 0;
	[self reschedule];
}

- (void)handleWakeFromSleep:(NSNotification *)note
{
	NSLog(@"woke from sleep");
	[self reschedule];
}

- (IBAction)goToSite:(id)sender
{
	if (rhpChecker.status == RHPCHECKER_COOKIE_PROBLEM) {
		[self showLoginWindow];
	}
	else {
		[[NSWorkspace sharedWorkspace] openURL:[rhpChecker siteVisitUrl]];
	}
}

- (IBAction)openInSafari:(id)sender
{
	if ([sender window]==loginWindow) {
		[loginWindow close];
	}
	NSLog(@"opening safari");
	[[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:[rhpChecker siteLoginUrl]]
					withAppBundleIdentifier:@"com.apple.Safari"
									options:NSWorkspaceLaunchDefault
			 additionalEventParamDescriptor:nil
						  launchIdentifiers:nil];
}

- (void)menuWillOpen:(NSMenu *)menu
{
	[self checkSoon];
}

@end
