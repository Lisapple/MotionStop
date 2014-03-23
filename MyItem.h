//
//  MyItem.h
//  Motion Stop!
//
//  Created by Max on 07/02/2010.
//  Copyright 2010 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MyItem : NSObject {
	BOOL enabled;
	NSString * name;
	NSImage * image;
}

@property (readwrite) BOOL enabled;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSImage * image;

+ (MyItem *)itemWithName:(NSString *)aName withImage:(NSImage *)anImage;

@end
