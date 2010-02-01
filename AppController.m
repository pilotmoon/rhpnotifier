#import "AppController.h"
#include "debug.h"

#define INTERVAL_RECONNECT 10
#define INTERVAL_MIN 60
#define INTERVAL_MAX 1800
#define INTERVAL_MULTIPLIER 1.2

@implementation AppController

@synthesize ready;
@synthesize statusLine;
@synthesize resultLine;
@synthesize loginLine;

- (BOOL)pulldown
{
	return NO;
}

- (id)init
{
	[super init];
	
	lct = [NSDate distantPast];
	interval=0;
	
	// register for wake from sleep notification
	[[[NSWorkspace sharedWorkspace] notificationCenter]
	 addObserver:self
		selector:@selector(handleWakeFromSleep:)
			name:NSWorkspaceDidWakeNotification 
		  object:[NSWorkspace sharedWorkspace]];
	
	rhpChecker = [[RhpChecker alloc] init];
	[rhpChecker setDelegate:self];
	
	self.ready=NO;
	[self updateResult];
	[self updateStatus];
	
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
	
	// kick off timer system
	[self timerRoutine:nil];
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
			self.statusLine=@"Status: Safari login required";
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
	[statusMenu update];
	
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
	
	// schedule next check
	lct = [NSDate date];
	
	timer = [NSTimer timerWithTimeInterval:interval target:self 
								  selector:@selector(timerRoutine:)
								  userInfo:nil
								   repeats:NO];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
	
	NSLog(@"last checked at %@", lct);
	NSLog(@"new interval is %f", interval);
	NSLog(@"timer scheduled for %@", [timer fireDate]);
	
	self.ready=YES;
}

- (void)timerRoutine:(NSTimer *)unused
{
	NSLog(@"--> timer routine fired");
	[rhpChecker check];
}

- (void)reschedule
{
	// if not in course of a check, reschedule check with current value of interval
	if (ready) {
		NSAssert([timer isValid], @"timer is not valid");
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
	LSOpenCFURLRef((CFURLRef)[rhpChecker siteVisitUrl], NULL);
}

- (void)menuWillOpen:(NSMenu *)menu
{
	[self checkSoon];
}

@end
