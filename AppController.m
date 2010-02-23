#import "AppController.h"
#import "LoginItem.h"

#define INTERVAL_RECONNECT 10
#define INTERVAL_MIN 60
#define INTERVAL_MAX 1800
#define INTERVAL_MULTIPLIER 1.2

static NSString * const  permissionKey = @"RHPCookiePermission";

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
	[self updatePlayerName];
	
	// register for wake from sleep notification
	[[[NSWorkspace sharedWorkspace] notificationCenter]
	 addObserver:self
		selector:@selector(handleWakeFromSleep:)
			name:NSWorkspaceDidWakeNotification 
		  object:[NSWorkspace sharedWorkspace]];
	
	rhpChecker = [[RhpChecker alloc] init];
	[rhpChecker setDelegate:self];

	// load up status icons
	statusImageBlack=[NSImage imageNamed:@"PawnStatusBlack.png"];
	statusImageRed=[NSImage imageNamed:@"PawnStatusRed.png"];
	statusImageGrey=[NSImage imageNamed:@"PawnStatusGrey.png"];
	NSSize size={13, 17};
	[statusImageBlack setSize:size];
	[statusImageRed setSize:size];
	[statusImageGrey setSize:size];
	
	rhpChecker.permission=[[NSUserDefaults standardUserDefaults] boolForKey:permissionKey];
	
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
	
	[self updateIcon];
	
	// schedule the very first check
	[self schedule];
}

- (void)prepareLoginWindow
{
	NSString *path=[[NSBundle mainBundle] pathForResource:@"Login"
												   ofType:@"html"];
	self.loginWindowText = [[NSAttributedString alloc] initWithPath:path
												 documentAttributes:nil];
	[loginButton setTitle:@"Visit Site in Safari"];
	[loginButton setAction:@selector(openInSafari:)];
	[loginWindow setDelegate:self];
}


- (void)preparePermissionWindow
{
	NSString *path=[[NSBundle mainBundle] pathForResource:@"Permission"
												   ofType:@"html"];
	self.loginWindowText = [[NSAttributedString alloc] initWithPath:path
												 documentAttributes:nil];
	[loginButton setTitle:@"Connect"];
	[loginButton setAction:@selector(givePermission:)];
	[loginWindow setDelegate:self];
}

- (void)showLoginWindow
{
	NSLog(@"showing login window");
	[self prepareLoginWindow];
	[NSApp activateIgnoringOtherApps:YES];
	[NSApp runModalForWindow:loginWindow];
}

- (void)showPermissionWindow
{
	NSLog(@"showing permission window");
	[self preparePermissionWindow];
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

- (void)updateIcon
{
	switch(rhpChecker.status) {
		case RHPCHECKER_OK:
			switch (rhpChecker.gamesWaiting) {
				case 0:
					[statusItem setTitle:nil];	
					[statusItem setImage:statusImageBlack];
					break;
				default:
					[statusItem setTitle:[NSString stringWithFormat:@"%d",rhpChecker.gamesWaiting]];			
					[statusItem setImage:statusImageRed];
					break;
			}
			break;
		default:
			[statusItem setTitle:nil];
			[statusItem setImage:statusImageGrey];
			break;
	}
}

- (void)updateResult
{
	switch(rhpChecker.status) {
		case RHPCHECKER_OK:
			switch (rhpChecker.gamesWaiting) {
				case 1:
					self.resultLine=@"1 game waiting";
					break;
				default:
					self.resultLine=[NSString stringWithFormat:@"%d games waiting", rhpChecker.gamesWaiting];
					break;
			}
			break;
	
		case RHPCHECKER_COOKIE_PROBLEM:
		case RHPCHECKER_NO_PERMISSION:
			self.resultLine=@"Connect...";
			break;
	
		default:
			self.resultLine=@"Go to site";
			break;
	}
	
}

- (void)updatePlayerName
{
	if ([self statusOk]) {
		self.loginLine=[NSString stringWithFormat:@"Player name: %@",
						rhpChecker.playerName];
	}
	else {
		self.loginLine=@"Player name: (unknown)";
	}
}

- (void)updateStatus
{
	switch(rhpChecker.status)
	{
		case RHPCHECKER_OK:
			self.statusLine=@"Status: OK";
			break;
		case RHPCHECKER_NO_PERMISSION:
			self.statusLine=@"Status: Ready to login";
			break;
		case RHPCHECKER_NEVER_CHECKED:
			self.statusLine=@"Status: Application starting...";
			break;
		case RHPCHECKER_COOKIE_PROBLEM:
			self.statusLine=@"Status: Cookie needed";
			break;
		case RHPCHECKER_OFFLINE:
			self.statusLine=@"Status: Offline";
			break;
		case RHPCHECKER_CONNECTION_PROBLEM:
			self.statusLine=@"Status: Could not connect";
			break;
		case RHPCHECKER_RESPONSE_PROBLEM:
		default:
			self.statusLine=@"Status: Site response error";
			break;
	}
}

- (void)rhpCheckerWillCheck
{
	self.ready=NO;
	self.statusLine=@"Status: Checking...";
	[self willChangeValueForKey:@"statusOk"];
	[self willChangeValueForKey:@"cookieOk"];
	[statusMenu update];
}

- (void)rhpCheckerDidCheck
{
	NSLog(@"check complete");

	[self didChangeValueForKey:@"statusOk"];
	[self didChangeValueForKey:@"cookieOk"];
	
	// update ui
	[self updateResult];
	[self updateStatus];
	[self updatePlayerName];
	[self updateIcon];
	
	if ([self statusOk]) {
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

- (IBAction)checkNow:(id)sender
{
	if([self ready]) {
		interval = 0;
		[self reschedule];	
	}
}

- (void)handleWakeFromSleep:(NSNotification *)note
{
	NSLog(@"woke from sleep");
	[self reschedule];
}

- (IBAction)givePermission:(id)sender
{
	if ([sender window]==loginWindow) {
		[loginWindow close];
	}
	rhpChecker.permission=YES;
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:permissionKey];
	[self checkSoon];
}

- (IBAction)goToSite:(id)sender
{
	if (rhpChecker.status == RHPCHECKER_COOKIE_PROBLEM) {
		[self showLoginWindow];
	}
	else if (rhpChecker.status == RHPCHECKER_NO_PERMISSION) {
		[self showPermissionWindow];
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
	
	// trigger refresh of item
	[self willChangeValueForKey:@"startAtLogin"];
	[self didChangeValueForKey:@"startAtLogin"];
}

- (BOOL)statusOk
{
	return (rhpChecker.status==RHPCHECKER_OK);
}

- (BOOL)cookieOk
{
	return (rhpChecker.status!=RHPCHECKER_COOKIE_PROBLEM && 
			rhpChecker.status!=RHPCHECKER_NO_PERMISSION);
}

- (NSURL *)appURL
{
	return [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
}

- (BOOL)startAtLogin
{
	return [LoginItem willStartAtLogin:[self appURL]];
}

- (void)setStartAtLogin:(BOOL)enabled
{
	[self willChangeValueForKey:@"startAtLogin"];
	[LoginItem setStartAtLogin:[self appURL] enabled:enabled];
	[self didChangeValueForKey:@"startAtLogin"];
}


@end
