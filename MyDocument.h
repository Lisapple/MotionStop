//
//  MyDocument.h
//  Motion Stop!
//
//  Created by Max on 19/11/2009.
//  Copyright 2009 Lis@cintosh. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import "MyTableView.h"
#import "MyItem.h"

@interface MyDocument : NSDocument 
#if defined(MAC_OS_X_VERSION_10_6)
<NSTableViewDelegate, NSTableViewDataSource, NSMenuDelegate>
#endif
{
	QTMovie * movie;
	QTCaptureSession * session;
	QTMovieView * movieView;
	QTCaptureView * captureView;
	CVImageBufferRef imageBuffer;
	NSModalSession modalSession;
	
	NSMutableArray * frameArray;
	
	MyTableView * tableView;
	///***///
	
	NSWindow * fpsWindow, * timerWindow, * savingWindow;
	NSImageView * outputImageView;
	NSTextField * fpsLabel, * timeLabel, * frameLabel;
	NSSlider * fpsSlider, * rowHeightSlider, * compressSlider, * timeSlider;
	
	NSMutableArray * contentArray;
		
	NSProgressIndicator * renderingProgress, * savingProgress;
	NSWindow * renderingWindow, * outputWindow;
	NSTextField * renderingLabel;
		
	NSButton * closeTimerButton;
	
	BOOL continueRendering;
	BOOL isRunning;
		
	NSMenu * tableViewMenu;
		
	NSInteger fps, index;
	
	NSView * compressView, * backupView;
	IBOutlet NSButton * backupButton;
	float interval;
	NSTimer * timer;
	NSProgressIndicator * timingIndicator;
		
	QTCaptureDevice * currentDevice;
	
	BOOL exportEnabled;
}

@property (nonatomic, retain) NSMutableArray * frameArray;


@property (assign) IBOutlet QTMovieView * movieView;
@property (assign) IBOutlet QTCaptureView * captureView;

@property (assign) IBOutlet MyTableView * tableView;

///***///
@property (assign) IBOutlet NSWindow * fpsWindow, * timerWindow, * savingWindow;
@property (assign) IBOutlet NSImageView * outputImageView;
@property (assign) IBOutlet NSTextField * fpsLabel, * timeLabel, * frameLabel;
@property (assign) IBOutlet NSSlider * fpsSlider, * rowHeightSlider, * compressSlider, * timeSlider;

@property (assign) IBOutlet NSProgressIndicator * renderingProgress, * savingProgress;
@property (assign) IBOutlet NSWindow * renderingWindow, * outputWindow;

@property (assign) IBOutlet NSTextField * renderingLabel;

@property (assign) IBOutlet NSButton * closeTimerButton;

@property (assign) IBOutlet NSMenu * tableViewMenu;

@property (assign) IBOutlet NSView * compressView, * backupView;

@property (assign) IBOutlet NSProgressIndicator * timingIndicator;

#pragma mark NSUndoManager
- (void)changeKeyPath:(NSString *)keyPath ofObject:(id)object toValue:(id)newValue;
- (void)addItem:(MyItem *)anItem;
- (void)addItems:(NSArray *)items atIndexes:(NSIndexSet *)indexes;
- (void)removeItemsAtIndexes:(NSIndexSet *)indexes;
- (IBAction)deleteSelection:(id)sender;

#pragma mark Miscellaneous
- (void)selectInputDevice:(id)sender;

#pragma mark FPS settings
- (IBAction)beginfpsSheet:(id)sender;
- (IBAction)fpsSliderDidChange:(id)sender;
- (IBAction)endfpsSheet:(id)sender;

#pragma mark Timer settings
- (IBAction)beginTimerSheet:(id)sender;
- (IBAction)timeSliderDidChange:(id)sender;
- (IBAction)endTimerSheet:(id)sender;

- (IBAction)setTimerState:(id)sender;
- (void)updateTimer;

#pragma mark Frame taking
- (IBAction)take:(id)sender;
- (void)frameArrayCountDidChange:(NSNotification *)aNotification;
- (void)updateFrameLabel;

#pragma mark Rendering
- (IBAction)render:(id)sender;
- (IBAction)abortRendering:(id)sender;
- (QTMovie *)createMovieWithTimeScale:(long)timeScale;

/*
 #pragma mark Capture settings
 - (void)captureOutput:(QTCaptureOutput *)captureOutput didOutputVideoFrame:(CVImageBufferRef)videoFrame withSampleBuffer:(QTSampleBuffer *)sampleBuffer fromConnection:(QTCaptureConnection *)connection;
*/ 

#pragma mark Import
- (IBAction)importImageFiles:(id)sender;

#pragma mark Export
- (IBAction)exportAsQuickTimeMovie:(id)sender;
- (IBAction)exportAsImageSequence:(id)sender;

#pragma mark Application Update
- (void)lookForUpdate;

- (IBAction)reportBug:(id)sender;
- (IBAction)visitWebsite:(id)sender;

/***
#pragma mark NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

#pragma mark Loading
- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError;

#pragma mark Saving
- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError;

#pragma mark Application Ending
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication;
- (void)applicationWillTerminate:(NSNotification *)aNotification;
***/

@end