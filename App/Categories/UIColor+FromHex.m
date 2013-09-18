//
//  UIColor+FromHex.m
//  Shelvz
//
//  Created by Pavel on 27.08.12.
//  Copyright (c) 2012 Cashklick. All rights reserved.
//

#import "UIColor+FromHex.h"

@implementation UIColor (FromHex)

+ (UIColor *)colorWithHexCode:(NSString *)colorCode {
	unsigned red, green, blue;
	sscanf([colorCode cStringUsingEncoding:NSASCIIStringEncoding], "#%2x%2x%2x", &red, &green, &blue);
	return [UIColor colorWithRed:red / 255.f green:green / 255.f blue:blue / 255.f alpha:1.f];
}

@end
