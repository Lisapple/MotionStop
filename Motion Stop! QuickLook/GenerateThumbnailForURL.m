#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>

/* -----------------------------------------------------------------------------
 Generate a thumbnail for file
 
 This function's job is to create thumbnail for designated file as fast as possible
 ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void * thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
	/*
	 CFTypeRef keys[1], values[1];
	 keys[0] = kQLPreviewPropertyDisplayNameKey;
	 values[0] = CFStringCreateWithCString(NULL, "Image Details", kCFStringEncodingMacRoman);
	 CFDictionaryRef properties = CFDictionaryCreate(NULL, (const void **)keys, (const void **)values, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	 */
	
	NSURL * anURL = [[NSBundle URLsForResourcesWithExtension:@"jpg" subdirectory:@"Resources/" inBundleWithURL:(NSURL *)url] objectAtIndex:0];
	/*
	 CGContextRef context = QLThumbnailRequestCreateContext(thumbnail, maxSize, YES, NULL);
	 NSLog(@"%@", [NSData dataWithContentsOfURL:anURL]);
	 NSBitmapImageRep * image = [NSBitmapImageRep imageRepWithData:[NSData dataWithContentsOfURL:anURL]];
	 CGContextDrawImage(context, CGRectMake(0., 0., maxSize.width, maxSize.height), [image CGImage]);
	 QLThumbnailRequestFlushContext(thumbnail, context);
	 */
	QLThumbnailRequestSetImageAtURL(thumbnail, (CFURLRef)anURL, NULL);
	
    return noErr;
}

void CancelThumbnailGeneration(void * thisInterface, QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}
