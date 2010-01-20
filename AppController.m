#import "AppController.h"

#define INITIAL_DELAY 60
#define DELAY_MAX 1800
#define DELAY_MULTIPLIER 1.2

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
	
	rhpChecker = [[RhpChecker alloc] init];
	
	taskRunner = [[BackgroundTaskRunner alloc] init];
	[taskRunner setDelegate:self];

	self.ready=NO;
	[self updateResult];
	[self updateStatus];
	[self resetDelay];
	
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
	[taskRunner runNow];
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
			self.loginLine=[NSString stringWithFormat:@"Logged in as %@", rhpChecker.playerName];
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

- (void)scheduleTask
{
	if(rhpChecker.status!=RHPCHECKER_OK) {
		[self resetDelay];
	}
	NSLog(@"Scheduling next check in %f seconds", delay);
	[taskRunner performSelector:@selector(runNow) withObject:nil afterDelay:delay];
	[self increaseDelay];
}

- (void)cancelTask
{
	NSLog(@"Cancelling scheduled check");
	[NSObject cancelPreviousPerformRequestsWithTarget:taskRunner];
	[self resetDelay];
}

- (void)task
{
	[rhpChecker check];
}

- (void)willRun
{
	self.ready=NO;
	self.statusLine=@"Status: Checking...";
}

- (void)didRun
{
	[self updateResult];
	[self updateStatus];
	[self scheduleTask];
	self.ready=YES;
}

- (IBAction)checkNow:(id)sender
{
	[self cancelTask];
	[taskRunner runNow];
}

- (void)resetDelay
{
	delay=INITIAL_DELAY;
}

- (void)increaseDelay
{
	delay*=DELAY_MULTIPLIER;
	if (delay>DELAY_MAX) {
		delay=DELAY_MAX;
	}
}

- (IBAction)goToSite:(id)sender
{
	LSOpenCFURLRef((CFURLRef)[rhpChecker siteVisitUrl], NULL);
}

- (void)menuWillOpen:(NSMenu *)menu
{
	[self checkNow:nil];
}

@end
