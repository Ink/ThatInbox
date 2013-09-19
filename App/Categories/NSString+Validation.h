//
//  NSString+Validation.h
//  Shelvz
//
//  Created by Andrey Yastrebov on 10.08.12.
//  Copyright (c) 2012 Cashklick. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Validation)
- (BOOL)isConformsRegex:(NSString *)regexPattern;
@end
