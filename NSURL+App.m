#import "NSURL+App.h"

@implementation NSURL (App)

- (void)openInAppWithIdentifier:(NSString *)identifier
{
	FSRef appref = { 0 };
	if (![[[NSWorkspace sharedWorkspace]
		   absolutePathForAppBundleWithIdentifier:identifier] getFSRef:&appref]) {
		NSLog(@"failed to get fsref for app %@", identifier);
		return;
	}
	LSApplicationParameters params = {
		0, kLSLaunchDefaults, &appref, NULL, NULL, NULL, NULL
	};
	LSOpenURLsWithRole((CFArrayRef)[NSArray arrayWithObject:self],
					   0, NULL, &params, NULL, 0);
}

@end
