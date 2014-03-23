//
//  MSTableView.h
//  Motion Stop!
//
//  Created by Max on 18/01/2010.
//  Copyright 2010 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MyTableView : NSTableView
#if defined(MAC_OS_X_VERSION_10_6)
<NSTableViewDelegate, NSTableViewDataSource>
#endif
{
	NSMutableArray * frameArray;
	NSImageView * outputImageView;
}

@property (nonatomic, retain) NSMutableArray * frameArray;
@property (nonatomic, retain) NSImageView * outputImageView;

#pragma mark NSTableView Resize
- (IBAction)rowHeightDidChange:(id)sender;

#pragma mark NSMenu TableView
- (IBAction)checkSelection:(id)sender;
- (IBAction)uncheckSelection:(id)sender;

- (void)moveObjectFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;

@end
