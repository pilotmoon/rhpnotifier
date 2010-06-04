#import <Foundation/Foundation.h>

@interface PMLoginItemsController : NSObject {
	__strong LSSharedFileListRef loginItems;
}

// "Start at Login" property to be bound to by prefs checkbox.
@property BOOL startAtLogin;

- (void)cleanup;
- (BOOL)startAtLogin;
- (void)setStartAtLogin:(BOOL)enabled;

@end
