//
//  MSTableView.m
//  Motion Stop!
//
//  Created by Max on 18/01/2010.
//  Copyright 2010 Lis@cintosh. All rights reserved.
//

#import "MyTableView.h"


@implementation MyTableView

@synthesize frameArray, outputImageView;

#pragma mark NSTableView Resize
- (IBAction)rowHeightDidChange:(id)sender
{
	[self setRowHeight:(CGFloat)[sender intValue]];
}

#pragma mark NSTableViewDelegate
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if (self.selectedRow < 0)
		[outputImageView setImage:[[frameArray lastObject] image]];
	else
		[outputImageView setImage:[[frameArray objectAtIndex:self.selectedRow] image]];
}

#pragma mark NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return frameArray.count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return [[frameArray objectAtIndex:rowIndex] valueForKey:[aTableColumn identifier]];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	[[frameArray objectAtIndex:rowIndex] setValue:anObject forKey:[aTableColumn identifier]];
}

#pragma mark NSTableView Drag Method
- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	NSData * data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
	[pboard declareTypes:[NSArray arrayWithObject:@"tableViewDataType"] owner:self];
	[pboard setData:data forType:@"tableViewDataType"];
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	if ([self selectedRowIndexes].count > 1)
		return NSDragOperationNone;
	else
		return NSDragOperationMove;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard * pboard = [info draggingPasteboard];
    NSData * rowData = [pboard dataForType:@"tableViewDataType"];
    NSIndexSet * rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
	/*
	NSInteger rowIndex = [rowIndexes firstIndex];
	id object = [NSDictionary dictionaryWithDictionary:[frameArray objectAtIndex:rowIndex]];
	[frameArray removeObjectAtIndex:rowIndex];
	[frameArray insertObject:object atIndex:((row >= frameArray.count)? row-1: row)];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"FrameArrayHasChanged" 
														object:nil];	
	*/
	[self moveObjectFromIndex:[rowIndexes firstIndex] toIndex:row];
	NSUndoManager * undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] moveObjectFromIndex:row toIndex:[rowIndexes firstIndex]];
	
	return YES;
}

- (void)moveObjectFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex
{
	id object = [frameArray objectAtIndex:fromIndex];
	[frameArray removeObjectAtIndex:fromIndex];
	[frameArray insertObject:object atIndex:(toIndex > frameArray.count)? toIndex-1: toIndex];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"FrameArrayHasChanged" 
														object:nil];
}

#pragma mark NSMenu TableView

- (IBAction)checkSelection:(id)sender
{
	for (id item in [frameArray objectsAtIndexes:[self selectedRowIndexes]])
		[item setValue:[NSNumber numberWithBool:1] forKey:@"enabled"];
}

- (IBAction)uncheckSelection:(id)sender
{
	for (id item in [frameArray objectsAtIndexes:[self selectedRowIndexes]])
		[item setValue:[NSNumber numberWithBool:0] forKey:@"enabled"];
}

@end
