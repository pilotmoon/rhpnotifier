#import "NSString+FSRef.h"

@implementation NSString (FSRef)

+ (NSString *)stringWithFSRef:(const FSRef *)aFSRef
{
	CFURLRef theURL = CFURLCreateFromFSRef( kCFAllocatorDefault, aFSRef );
	NSString* thePath = [(NSURL *)theURL path];
	CFRelease ( theURL );
	return thePath;
}

- (BOOL)getFSRef:(FSRef *)aFSRef
{
	return FSPathMakeRef( (const UInt8 *)[self fileSystemRepresentation],
						 aFSRef, NULL ) == noErr;
}

@end
