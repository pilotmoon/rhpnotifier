//
//  rhpcheckerAppDelegate.h
//  rhpchecker
//
//  Created by Nicholas Moore on 19/01/2010.
//  Copyright 2010 Nicholas Moore. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface rhpcheckerAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
