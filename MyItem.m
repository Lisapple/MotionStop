//
//  MyItem.m
//  Motion Stop!
//
//  Created by Max on 07/02/2010.
//  Copyright 2010 Lis@cintosh. All rights reserved.
//

#import "MyItem.h"


@implementation MyItem

@synthesize enabled, name, image;

+ (MyItem *)itemWithName:(NSString *)aName withImage:(NSImage *)anImage
{
	MyItem * anItem = [[MyItem alloc] init];
	anItem.name = aName;
	anItem.image = anImage;
	anItem.enabled = YES;
	return [anItem autorelease];
}

@end
