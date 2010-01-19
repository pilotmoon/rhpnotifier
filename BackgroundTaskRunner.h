#import <Foundation/Foundation.h>


@interface BackgroundTaskRunner : NSObject {
	id delegate;
}

@property id delegate;

- (void)runNow;

@end


@interface NSObject (BackgroundTaskRunnerDelegate)

// the task method itself, to be run in a background thread
- (void)task;

// called in the main thread before task is run
- (void)willRun;

// called in the main thread when task finishes
- (void)didRun;

@end
