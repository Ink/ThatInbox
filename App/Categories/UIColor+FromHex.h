//
//  UIColor+FromHex.h
//  Shelvz
//
//  Created by Pavel on 27.08.12.
//  Copyright (c) 2012 Cashklick. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (FromHex)

// Color code should be "#RRGGBB"
+ (UIColor *)colorWithHexCode:(NSString *)colorCode;

@end
