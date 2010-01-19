#import "BackgroundTaskRunner.h"


@implementation BackgroundTaskRunner

@synthesize delegate;

- (void)threadRoutine
{
	if ([delegate respondsToSelector:@selector(willRun)]) {
		[delegate performSelectorOnMainThread:@selector(willRun) withObject:nil waitUntilDone:YES];
	}

	if ([delegate respondsToSelector:@selector(task)]) {
        [delegate task];		
	}
    else { 
        [NSException raise:NSInternalInconsistencyException
					format:@"Delegate doesn't respond to task"];
    }
	
	if ([delegate respondsToSelector:@selector(didRun)]) {
		[delegate performSelectorOnMainThread:@selector(didRun) withObject:nil waitUntilDone:YES];
	}
}

- (void)runNow
{
	NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(threadRoutine) object:nil];	
	[thread start];
}

@end
