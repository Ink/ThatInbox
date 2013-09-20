//
//  NSString+Email.m
//  AFMailClient
//
//  Created by Andrey Yastrebov on 22.08.13.
//  Copyright (c) 2013 AgileFusion. All rights reserved.
//

#import "NSString+Email.h"

@implementation NSString (Email)

- (BOOL)isEmailValid
{
    // The NSRegularExpression class is currently only available in the Foundation framework of iOS 4
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}\\b" options:NSRegularExpressionCaseInsensitive | NSRegularExpressionAnchorsMatchLines error:&error];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:self options:0 range:NSMakeRange(0, [self length])];
    
    if (!error && numberOfMatches > 0)
    {
        return YES;
    }
    
    return NO;
}

- (NSString *)emailDomain
{
    if ([self isEmailValid])
    {
        NSString *fullDomain = [[self componentsSeparatedByString:@"@"] lastObject];
        return [[fullDomain componentsSeparatedByString:@"."] objectAtIndex:0];
    }
    else
    {
        return nil;
    }
}

- (NSString *)emailDomainUpperCase
{
    NSString *domain = [self emailDomain];
    if (domain)
    {
        domain = [domain capitalizedString];
    }
    return domain;
}

@end
