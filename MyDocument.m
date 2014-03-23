//
//  MyDocument.m
//  Motion Stop!
//
//  Created by Max on 19/11/2009.
//  Copyright 2009 Lis@cintosh. All rights reserved.
//


#import "MyDocument.h"

@implementation MyDocument

@synthesize frameArray;

@synthesize movieView, captureView;
@synthesize outputImageView;
@synthesize outputWindow;
@synthesize tableView, rowHeightSlider, tableViewMenu;
@synthesize timerWindow, timeSlider, timeLabel;

@synthesize fpsWindow, fpsSlider, fpsLabel;
@synthesize renderingWindow, renderingProgress, renderingLabel;
@synthesize compressView, compressSlider;
@synthesize backupView;

@synthesize closeTimerButton;
@synthesize savingWindow, savingProgress;

@synthesize timingIndicator;

@synthesize frameLabel;

- (id)init
{
    if (self = [super init])
	{
		fps = 1;
		index = 0;
		interval = 10.;
		
		exportEnabled = NO;
		
		@try {
			currentDevice = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
		}
		@catch (NSException *exception) {
		}
		@finally {
		}
	}
    return self;
}

- (NSString *)windowNibName
{
	return @"MyDocument";
}

- (void)windowControllerWillLoadNib:(NSWindowController *)windowController
{
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
	NSMenu * menu = [[NSMenu alloc] initWithTitle:@"Menu"];
	for (id device in [QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeVideo]) {
		NSMenuItem * menuItem = [[NSMenuItem alloc] initWithTitle:[device localizedDisplayName] 
														   action:@selector(selectInputDevice:)
													keyEquivalent:@""];
		[menuItem setRepresentedObject:device];
		if (device == currentDevice)
			[menuItem setState:NSOnState];
		[menu addItem:menuItem];
		[menuItem release];
	}
	
	NSMenu * deviceMenu = [[[NSApp mainMenu] itemWithTitle:@"Device"] submenu];
	[[deviceMenu itemWithTitle:@"Video"] setSubmenu:menu];
	[menu release];
	
	menu = [[NSMenu alloc] initWithTitle:@"Menu"];
	for (id item in [QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeSound]) {
		NSMenuItem * menuItem = [[NSMenuItem alloc] initWithTitle:[item localizedDisplayName] 
														   action:nil//unimplemented for sound device
													keyEquivalent:@""];
		[menuItem setRepresentedObject:item];
		[menu addItem:menuItem];
		[menuItem release];
	}	
	
	[[deviceMenu itemWithTitle:@"Sound"] setSubmenu:menu];
	[menu release];
	
	NSError * error = nil;
	movie = [[QTMovie alloc] initToWritableData:[NSMutableData data] error:&error];
	[movie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
	
	[currentDevice open:nil];
	
	session = [[QTCaptureSession alloc] init];
	QTCaptureDeviceInput * input = [[QTCaptureDeviceInput alloc] initWithDevice:currentDevice];
	[session addInput:input error:&error];
	[input release];
	
	QTCaptureDecompressedVideoOutput * output = [[QTCaptureDecompressedVideoOutput alloc] init];
	[output setDelegate:self];
	[session addOutput:output error:&error];
	
	[captureView setDelegate:self];
	[captureView setCaptureSession:session];
	[session startRunning];
	[session release];
	
	[movieView setMovie:movie];
	
	frameArray = [[NSMutableArray alloc] initWithArray:frameArray];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(frameArrayCountDidChange:) 
												 name:@"FrameArrayHasChanged" 
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"FrameArrayHasChanged" 
														object:nil];
	tableView.frameArray = frameArray;
	tableView.outputImageView = outputImageView;
	
	[tableView setDataSource:tableView];
	[tableView setDelegate:tableView];
	[tableView registerForDraggedTypes:[NSArray arrayWithObjects:@"tableViewDataType", nil]];
	
	[super windowControllerDidLoadNib:aController];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	//[NSThread detachNewThreadSelector:@selector(lookForUpdate) toTarget:self withObject:nil];
}

/*
 - (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
 {
 return YES;
 }
 */

#pragma mark NSUndoManager

- (void)changeKeyPath:(NSString *)keyPath ofObject:(id)object toValue:(id)newValue
{
	[object setValue:newValue forKey:keyPath];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"FrameArrayHasChanged" 
														object:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
	if (oldValue == [NSNull null])
		oldValue = nil;
	
	NSLog(@"object:%@\nkeyPath:%@\nvalue:%@", object, keyPath, oldValue);
	
	NSUndoManager * undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] changeKeyPath:keyPath
												  ofObject:object
												   toValue:oldValue];
}

- (void)addItem:(MyItem *)anItem
{
	[self addItems:[NSArray arrayWithObject:anItem] atIndexes:nil];
}

- (void)addItems:(NSArray *)items atIndexes:(NSIndexSet *)indexes
{
	NSLog(@"add: %li item(s) total", (unsigned long)items.count);
	
	if (indexes == nil)
		indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(frameArray.count, items.count)];
	
	for (id item in items) {
		[item addObserver:self forKeyPath:@"enabled" options:NSKeyValueObservingOptionOld context:NULL];
		[item addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionOld context:NULL];
		[item addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionOld context:NULL];
	}
	[frameArray insertObjects:items atIndexes:indexes];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"FrameArrayHasChanged" 
														object:nil];
	
	NSUndoManager * undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] removeItemsAtIndexes:indexes];
}

- (void)removeItemsAtIndexes:(NSIndexSet *)indexes
{
	NSLog(@"remove: %li item(s) total", (unsigned long)[frameArray objectsAtIndexes:indexes].count);
	NSUndoManager * undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] addItems:[frameArray objectsAtIndexes:indexes]
											atIndexes:indexes];
	[frameArray removeObjectsAtIndexes:indexes];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"FrameArrayHasChanged" 
														object:nil];
}

- (IBAction)deleteSelection:(id)sender
{
	NSIndexSet * indexes = [tableView selectedRowIndexes];
	[self removeItemsAtIndexes:indexes];
}

#pragma mark Miscellaneous

- (void)selectInputDevice:(id)sender
{
	QTCaptureDevice * device = [sender representedObject];
	
	if (device != currentDevice) {
		[currentDevice close];
		currentDevice = device;
		
		NSError * error = nil;
		[currentDevice open:&error];
		
		[session stopRunning];
		
		session = [[QTCaptureSession alloc] init];
		QTCaptureDeviceInput * input = [[QTCaptureDeviceInput alloc] initWithDevice:currentDevice];
		[session addInput:input error:&error];
		[input release];
		
		QTCaptureDecompressedVideoOutput * output = [[QTCaptureDecompressedVideoOutput alloc] init];
		[output setDelegate:self];
		[session addOutput:output error:&error];
		
		[captureView setCaptureSession:session];
		[session startRunning];
		[session release];
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	NSLog(@"session: %@", session);
	[session stopRunning];
	
	if ([NSApp windows].count == 0) {
		NSMenu * fileMenu = [[[NSApp mainMenu] itemWithTitle:@"File"] submenu];
		[[fileMenu itemWithTag:2] setEnabled:NO];
	}
}

#pragma mark FPS settings
- (IBAction)beginfpsSheet:(id)sender
{
	[fpsSlider setIntValue:fps];
	[fpsLabel setStringValue:[NSString stringWithFormat:@"%li fps", (long)fps]];
	[NSApp beginSheet:fpsWindow modalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (IBAction)fpsSliderDidChange:(id)sender
{
	NSString * aString = [NSString stringWithFormat:@"%i fps", fpsSlider.intValue];
	[fpsSlider setToolTip:aString];
	[fpsLabel setStringValue:aString];
}

- (IBAction)endfpsSheet:(id)sender
{
	fps = fpsSlider.intValue;
	[fpsWindow orderOut:nil];
	[NSApp endSheet:fpsWindow];
}

#pragma mark Timer settings
- (IBAction)beginTimerSheet:(id)sender
{
	[timeSlider setIntValue:interval];
	[timeLabel setStringValue:[NSString stringWithFormat:@"Every %.0f sec", interval/10]];
	[NSApp beginSheet:timerWindow modalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (IBAction)timeSliderDidChange:(id)sender
{
	interval = timeSlider.floatValue;
	
	NSString * aString = @"";
	if (timeSlider.floatValue < 10)
		aString = [NSString stringWithFormat:@"%.0f ms", timeSlider.floatValue*100.];
	else
		aString = [NSString stringWithFormat:@"%i sec", timeSlider.intValue/10];
	
	[timeSlider setToolTip:aString];
	[timeLabel setStringValue:[@"Every " stringByAppendingString:aString]];
}

- (IBAction)endTimerSheet:(id)sender
{
	interval = timeSlider.intValue;
	[timerWindow orderOut:nil];
	[NSApp endSheet:timerWindow];
}

- (IBAction)setTimerState:(id)sender
{
	[timingIndicator stopAnimation:nil];
	
	if ([[sender title] isEqualToString:@"Run"]) {
		timer = [NSTimer scheduledTimerWithTimeInterval:0.1 
												 target:self 
											   selector:@selector(updateTimer) 
											   userInfo:nil 
												repeats:YES];
		isRunning = YES;
		[sender setTitle:@"Stop"];
	} else if ([[sender title] isEqualToString:@"Stop"]) {
		[timer invalidate];
		timer = nil;
		isRunning = NO;
		[timingIndicator setDoubleValue:0];
		[sender setTitle:@"Run"];
	}
	
	[timeSlider setEnabled:!isRunning];
	[closeTimerButton setEnabled:!isRunning];
	[timingIndicator setHidden:!isRunning];
}

- (void)updateTimer
{
	static int count = 0;
	count++;
	
	if (interval < 5) {
		[timingIndicator setIndeterminate:YES];
		[timingIndicator startAnimation:nil];
	} else {
		[timingIndicator setIndeterminate:NO];
		[timingIndicator incrementBy:100/interval];
	}
	
	if (count >= interval) {
		count = 0;
		[timingIndicator setDoubleValue:0];
		[self take:nil];
	}
}

#pragma mark Frame taking
- (IBAction)take:(id)sender
{
	CVImageBufferRef imageBufferRef;
	@synchronized (self) { imageBufferRef = CVBufferRetain(imageBuffer); }
	
	NSCIImageRep * imageRep = [NSCIImageRep imageRepWithCIImage:[CIImage imageWithCVImageBuffer:imageBufferRef]];
	NSImage * image = [[[NSImage alloc] initWithSize:[imageRep size]] autorelease];
	[image addRepresentation:imageRep];
	CVBufferRelease(imageBufferRef);
	image = [[NSImage alloc] initWithData:[image TIFFRepresentation]];
	
	NSString * name = [NSString stringWithFormat:@"Image %li", (long)++index];
	MyItem * anItem = [MyItem itemWithName:name withImage:image];
	/*
	 NSMutableDictionary * entry = [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithBool:YES], name, image, nil]
	 forKeys:[NSArray arrayWithObjects:@"check", @"name", @"image", nil]];
	 */
	[image release];
	[self addItem:anItem];
	
	[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:(frameArray.count-1)] byExtendingSelection:NO];
	[tableView scrollRowToVisible:(frameArray.count-1)];
}

- (void)frameArrayCountDidChange:(NSNotification *)aNotification //NSFrameArrayCountDidChangeNotification
{
	[self updateFrameLabel];
	[tableView reloadData];
}

- (void)updateFrameLabel
{
	NSInteger count = frameArray.count;
	if (count > 0) {
		if (count > 1)
			[frameLabel setStringValue:[NSString stringWithFormat:@"%li frames", (long)count]];
		else
			[frameLabel setStringValue:[NSString stringWithFormat:@"%li frame", (long)count]];
	} else {
		[frameLabel setStringValue:@""];
		[outputImageView setImage:nil];
	}
	/* doesn't work */
	/*
	NSMenu * fileMenu = [[[NSApp mainMenu] itemWithTitle:@"File"] submenu];
	[[[[fileMenu itemWithTitle:@"Export"] submenu] itemAtIndex:0] setEnabled:(count > 0)];
	[[[[fileMenu itemWithTitle:@"Export"] submenu] itemAtIndex:1] setEnabled:(count > 0)];
	*/
}

#pragma mark Rendering
- (IBAction)render:(id)sender
{
	[renderingProgress setIndeterminate:NO];
	[renderingProgress setDoubleValue:0.];
	modalSession = [NSApp beginModalSessionForWindow:renderingWindow];
	[NSApp runModalSession:modalSession];
	
	QTMovie * aMovie = [self createMovieWithTimeScale:fps];
	if (aMovie != nil)
		movie = aMovie;
	
	[NSApp endModalSession:modalSession];
	[renderingWindow orderOut:self];
	
	[movieView setMovie:movie];
	[movieView setNeedsDisplay:YES];
	
	[outputWindow makeKeyAndOrderFront:self];
}

- (IBAction)abortRendering:(id)sender
{
	continueRendering = NO;
	[renderingProgress setIndeterminate:YES];
}

- (QTMovie *)createMovieWithTimeScale:(long)timeScale
{	
	NSError * error = nil;
	QTMovie * aMovie = [[[QTMovie alloc] initToWritableData:[NSMutableData data] error:&error] autorelease];
	[aMovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
	
	long long timeValue = 1;
	QTTime duration = QTMakeTime(timeValue, timeScale);
	
	NSDictionary * attributes = [NSDictionary dictionaryWithObject:@"jpeg" forKey:QTAddImageCodecType];
	
	continueRendering = YES;
	int frame = 0;
	for (MyItem * entry in frameArray) {
		if (!continueRendering) return nil;
		
		[renderingLabel setStringValue:[NSString stringWithFormat:@"Rendering image: %i of %li", ++frame, (unsigned long)frameArray.count]];
		[renderingProgress incrementBy:100./frameArray.count];
		
		if (entry.enabled)
			[aMovie addImage:entry.image forDuration:duration withAttributes:attributes];
	}
	
	[aMovie setCurrentTime:[aMovie duration]];
	return aMovie;
}

#pragma mark Capture settings
- (void)captureOutput:(QTCaptureOutput *)captureOutput didOutputVideoFrame:(CVImageBufferRef)videoFrame withSampleBuffer:(QTSampleBuffer *)sampleBuffer fromConnection:(QTCaptureConnection *)connection
{
	CVImageBufferRef anImageBuffer;
    
    CVBufferRetain(videoFrame);
    
    @synchronized (self) {
        anImageBuffer = imageBuffer;
        imageBuffer = videoFrame;
    }
	
    CVBufferRelease(anImageBuffer);
}

#pragma mark Loading
- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	frameArray = [[NSMutableArray alloc] init];
	
	NSError * error = nil;
	NSData * data = [NSData dataWithContentsOfFile:[[absoluteURL path] stringByAppendingString:@"/project.xml"]];
	NSXMLDocument * xmlDoc = [[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyHTML error:&error];
	
	fps = [[[[xmlDoc rootElement] attributeForName:@"fps"] stringValue] intValue];
	index = [[[[xmlDoc rootElement] attributeForName:@"index"] stringValue] intValue];
	
	for (NSXMLElement * element in [[xmlDoc rootElement] elementsForName:@"frame"]) {		
		BOOL check = [[[[[element elementsForName:@"check"] objectAtIndex:0] childAtIndex:0] stringValue] boolValue];
		NSString * name = [[[[element elementsForName:@"name"] objectAtIndex:0] childAtIndex:0] stringValue];
		NSString * path = [[absoluteURL path] stringByAppendingString:[[[[element elementsForName:@"image"] objectAtIndex:0] childAtIndex:0] stringValue]];
		NSImage * image = [[NSImage alloc] initWithContentsOfFile:path];
		
		MyItem * item = [MyItem itemWithName:name withImage:image];
		item.enabled = check;
		
		[frameArray addObject:item];
		[image release];
	}
	
	[xmlDoc release];
	return YES;
}

- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel
{
	[savePanel setAccessoryView:backupView];
	return YES;
}

#pragma mark Saving
- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	[[NSFileManager defaultManager] createDirectoryAtPath:[absoluteURL path] withIntermediateDirectories:NO attributes:nil error:NULL];
	[[NSFileManager defaultManager] createDirectoryAtPath:[[absoluteURL path] stringByAppendingString:@"/Resources/"]
							  withIntermediateDirectories:NO 
											   attributes:nil
													error:NULL];
	
	NSXMLElement * root = (NSXMLElement *)[NSXMLNode elementWithName:@"movie"];
	NSXMLDocument * xmlDoc = [[[NSXMLDocument alloc] initWithRootElement:root] autorelease];
	[xmlDoc setVersion:@"1.0"];
	[xmlDoc setCharacterEncoding:@"UTF-8"];
	
	[root addAttribute:[NSXMLNode attributeWithName:@"fps" stringValue:[NSString stringWithFormat:@"%li", (long)fps]]];
	
	[NSApp beginSheet:savingWindow modalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[savingWindow makeKeyWindow];
	//[savingProgress startAnimation:self];
	[savingProgress setDoubleValue:0.];
	
	for (MyItem * item in frameArray) {
		NSXMLElement * frame = (NSXMLElement *)[NSXMLNode elementWithName:@"frame"];
		[root addChild:frame];
		
		[frame addChild:(NSXMLElement *)[NSXMLNode elementWithName:@"check"]];
		[[[frame elementsForName:@"check"] objectAtIndex:0] setStringValue:[[NSNumber numberWithBool:item.enabled] stringValue]];
		
		[frame addChild:(NSXMLElement *)[NSXMLNode elementWithName:@"name"]];
		[[[frame elementsForName:@"name"] objectAtIndex:0] setStringValue:item.name];
		
		[frame addChild:(NSXMLElement *)[NSXMLNode elementWithName:@"image"]];
		NSString * path = [NSString stringWithFormat:@"/Resources/%@.jpg", item.name];
		[[[frame elementsForName:@"image"] objectAtIndex:0] setStringValue:path];
		
		path = [absoluteURL.path stringByAppendingString:path];
		CGImageRef imageRef = [item.image CGImageForProposedRect:NULL // Default rect
														 context:[NSGraphicsContext currentContext]
														   hints:nil];
		NSBitmapImageRep * imageRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
		[[imageRep representationUsingType:NSJPEGFileType
								properties:@{ NSImageCompressionFactor : @0.85 }] writeToFile:path atomically:YES];
		
		[savingProgress incrementBy:(100./(float)frameArray.count)];
	}
	[root addAttribute:[NSXMLNode attributeWithName:@"index" stringValue:[NSString stringWithFormat:@"%li", (long)index]]];
	
	[savingWindow orderOut:nil];
	[NSApp endSheet:savingWindow];
	
	NSData * xmlData = [xmlDoc XMLDataWithOptions:NSXMLNodePrettyPrint];
	NSLog(@"%@", [absoluteURL path]);
	BOOL succes = [xmlData writeToFile:[[absoluteURL path] stringByAppendingString:@"/project.xml"] atomically:YES];
	
	Boolean backup;
	if ([backupButton state])
		backup = true;
	else
		backup = false;
	
	CSBackupSetItemExcluded((CFURLRef)absoluteURL, backup, false);
	
	return succes;
}

#pragma mark Import
- (IBAction)importImageFiles:(id)sender
{
	CGSize format = CVImageBufferGetDisplaySize(CVBufferRetain(imageBuffer));
	
	NSOpenPanel * openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowsMultipleSelection:YES];
	[openPanel setTitle:@"Import Images"];
	[openPanel setPrompt:@"Import"];
	
	NSArray * filetypes = @[@"bmp", @"gif", @"jpg", @"jpeg", @"jp2", @"pct", @"pict", @"png", @"tif", @"tiff"];
	[openPanel setAllowedFileTypes:filetypes];
	
	if ([openPanel runModal] == NSFileHandlingPanelOKButton) {
		for (NSURL * fileURL in openPanel.URLs) {
			NSString * name = [NSString stringWithFormat:@"Image %ld", (long)++index];
			NSImage * image = [[NSImage alloc] initWithContentsOfFile:fileURL.path];
			[image setSize:NSMakeSize(format.width, format.height)];
			
			MyItem * item = [MyItem itemWithName:name withImage:image];
			[self addItem:item];
			[image release];
		}
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"FrameArrayHasChanged" 
														object:nil];
}

#pragma mark Export
- (IBAction)exportAsQuickTimeMovie:(id)sender
{
	NSSavePanel * savePanel = [NSSavePanel savePanel];
	[savePanel setTitle:@"Export as QuickTime Movie"];
	[savePanel setNameFieldLabel:@"Export As:"];
	[savePanel setPrompt:@"Export"];
	//[savePanel setRequiredFileType:@"mov"];
	[savePanel setAllowedFileTypes:@[@"mov"]];
#if defined(MAC_OS_X_VERSION_10_6)
	NSString * name = [[[[NSApp mainWindow] title] stringByDeletingPathExtension] stringByAppendingString:@".mov"];
	[savePanel setNameFieldStringValue:name];
#endif
	
	NSDictionary * attributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:QTMovieFlatten];
	if ([savePanel runModal] == NSFileHandlingPanelOKButton)
		[[self createMovieWithTimeScale:fps] writeToFile:savePanel.URL.path.lastPathComponent
										  withAttributes:attributes];
}

- (IBAction)exportAsImageSequence:(id)sender
{
	NSSavePanel * savePanel = [NSSavePanel savePanel];
	[savePanel setMessage:@"Choose a directory where you want export image files:"];
	[savePanel setTitle:@"Export as Image Sequence"];
	[savePanel setNameFieldLabel:@"Directory:"];
	[savePanel setPrompt:@"Export"];
	[savePanel setAccessoryView:compressView];
#if defined(MAC_OS_X_VERSION_10_6)
	[savePanel setNameFieldStringValue:[[[NSApp mainWindow] title] stringByDeletingPathExtension]];
#endif
	
	if ([savePanel runModal] == NSFileHandlingPanelOKButton) {
		NSString * filename = savePanel.URL.path.lastPathComponent;
		if ([[NSFileManager defaultManager] fileExistsAtPath:filename isDirectory:nil]) {
			[[NSFileManager defaultManager] removeItemAtPath:filename error:NULL];
		}
		[[NSFileManager defaultManager] createDirectoryAtPath:filename withIntermediateDirectories:NO attributes:nil error:NULL];
		
		for (MyItem * item in frameArray) {
			NSString * path = [filename stringByAppendingFormat:@"/%@.jpg", item.name];
			
			NSBitmapImageRep * imageRep = [NSBitmapImageRep imageRepWithData:[item.image TIFFRepresentationUsingCompression:NSTIFFCompressionJPEG
																													 factor:0.85]];
			NSDictionary * properties = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:compressSlider.floatValue] 
																	forKey:NSImageCompressionFactor];
			[[imageRep representationUsingType:NSJPEGFileType properties:properties] writeToFile:path atomically:YES];
		}
	}
}

#pragma mark NSMenuDelegate
- (void)menuNeedsUpdate:(NSMenu *)menu
{
	if (menu == tableViewMenu) {
		[[tableViewMenu itemWithTag:0] setHidden:([tableView selectedRowIndexes].count != 0)];
		
		BOOL allChecked = YES;
		for (MyItem * item in [frameArray objectsAtIndexes:[tableView selectedRowIndexes]])
			allChecked &= item.enabled;
		[[tableViewMenu itemWithTag:1] setHidden:allChecked];
		
		BOOL allUnchecked = YES;
		for (MyItem * item in [frameArray objectsAtIndexes:[tableView selectedRowIndexes]])
			allUnchecked &= !item.enabled;
		[[tableViewMenu itemWithTag:2] setHidden:allUnchecked];
		
		[[tableViewMenu itemWithTag:3] setHidden:([tableView selectedRowIndexes].count == 0)];
	}
}

- (void)menu:(NSMenu *)menu willHighlightItem:(NSMenuItem *)item
{
	NSLog(@"willHighlightItem");
}

#pragma mark Application Update
- (void)lookForUpdate
{
	NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
	NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"http://lisapple.free.fr/motionStop/update.php?version=%@", version]];
	NSURLRequest * request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
	
	NSError * error;
	NSData * data = [[NSData alloc] initWithData:[NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error]]; 
	NSString * string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	[data release];
	
	if ([string isEqualToString:@"New version available."]) {
		NSInteger responce = [[NSAlert alertWithMessageText:@"New version available. Go to website to download it?" defaultButton:@"OK" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@""] runModal];
		
		switch (responce) {
			case NSAlertDefaultReturn://OK
				[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://lisapple.free.fr/motionStop/"]];
				break;
			case NSAlertAlternateReturn://Cancel
				break;
			default:
				break;
		}
	}
	
	[string release];
}

- (IBAction)reportBug:(id)sender
{
	[[NSWorkspace sharedWorkspace] launchApplication:@"Bugs Reporter.app"
											showIcon:NO 
										  autolaunch:NO];
	
}

- (IBAction)visitWebsite:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://lisapple.free.fr/motionStop/"]];
}

#pragma mark Application Ending
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return NO;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}

@end