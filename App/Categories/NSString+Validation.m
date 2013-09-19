//
//  NSString+Validation.m
//  Shelvz
//
//  Created by Andrey Yastrebov on 10.08.12.
//  Copyright (c) 2012 Cashklick. All rights reserved.
//

#import "NSString+Validation.h"

@implementation NSString (Validation)

- (BOOL)isConformsRegex:(NSString *)regexPattern
{
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexPattern
                                                                           options:0
                                                                             error:&error];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:self
                                                        options:0
                                                          range:NSMakeRange(0, [self length])];
    
    if (!error && numberOfMatches == 1)
    {
        return YES;
    }
    return NO;
}

@end
