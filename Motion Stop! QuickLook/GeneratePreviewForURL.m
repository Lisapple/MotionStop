#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>

/* -----------------------------------------------------------------------------
 Generate a preview for file
 
 This function's job is to create preview for designated file
 ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
	/*
	 CFTypeRef keys[1], values[1];
	 keys[0] = kQLPreviewPropertyDisplayNameKey;
	 values[0] = CFStringCreateWithCString(NULL, "Image Details", kCFStringEncodingMacRoman);
	 CFDictionaryRef properties = CFDictionaryCreate(NULL, (const void **)keys, (const void **)values, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	 */
	
	//NSURL * anURL = [[NSBundle URLsForResourcesWithExtension:@"jpg" subdirectory:@"Resources/" inBundleWithURL:(NSURL *)url] objectAtIndex:0];
	/*
	 CGContextRef context = QLThumbnailRequestCreateContext(thumbnail, maxSize, YES, NULL);
	 NSLog(@"%@", [NSData dataWithContentsOfURL:anURL]);
	 NSBitmapImageRep * image = [NSBitmapImageRep imageRepWithData:[NSData dataWithContentsOfURL:anURL]];
	 CGContextDrawImage(context, CGRectMake(0., 0., maxSize.width, maxSize.height), [image CGImage]);
	 QLThumbnailRequestFlushContext(thumbnail, context);
	 */
	
	//CGContextRef context = QLPreviewRequestCreateContext(preview, <#CGSize size#>, NO, NULL);
	
	//QLThumbnailRequestSetImageAtURL(thumbnail, (CFURLRef)anURL, NULL);
	//QLPreviewRequestFlushContext(preview, context);
	
	NSAutoreleasePool *pool;
    NSMutableString *html;
	
    pool = [[NSAutoreleasePool alloc] init];
	
	NSMutableDictionary * props = [[[NSMutableDictionary alloc] init] autorelease];
	[props setObject:@"UTF-8" forKey:(NSString *)kQLPreviewPropertyTextEncodingNameKey];
	[props setObject:@"text/html" forKey:(NSString *)kQLPreviewPropertyMIMETypeKey];
	
	html = [[[NSMutableString alloc] init] autorelease];
	[html appendString:@"<html><html><head><style> body {text-align:center;} img {width:25%;max-width:200px;}</style></head><body>"];
	
	NSArray * URLs = [NSBundle URLsForResourcesWithExtension:@"jpg" subdirectory:@"Resources/" inBundleWithURL:(NSURL *)url];
	
	NSMutableDictionary * items = [[NSMutableDictionary alloc] initWithCapacity:URLs.count];
	
	int i = 1; // Start at one to keep a matching with saved pictures (start with "image 1.jpg")
	for (NSURL * imageURL in URLs) {
		[html appendString:[NSString stringWithFormat:@"<img src=\"cid:img_%i\">", i]];
		
		NSMutableDictionary * imgProps = [[[NSMutableDictionary alloc] init] autorelease];
        [imgProps setObject:@"image/jpeg"
					 forKey:(NSString *)kQLPreviewPropertyMIMETypeKey];
		
		NSData * image = [NSData dataWithContentsOfFile:imageURL.path];
        [imgProps setObject:image
					 forKey:(NSString *)kQLPreviewPropertyAttachmentDataKey];
		
		[imgProps setObject:image
					 forKey:(NSString *)kQLPreviewPropertyAttachmentDataKey];
		
		[items setObject:imgProps
				  forKey:[NSString stringWithFormat:@"img_%i", i]];
		i++;
	}
	
	[props setObject:items
				 forKey:(NSString *)kQLPreviewPropertyAttachmentsKey];
	[items release];
	
	[html appendString:@"</body></html>"];
	QLPreviewRequestSetDataRepresentation(preview, (CFDataRef)[html dataUsingEncoding:NSUTF8StringEncoding], kUTTypeHTML, (CFDictionaryRef)props);
	[pool release];
	
	return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
	// implement only if supported
}
