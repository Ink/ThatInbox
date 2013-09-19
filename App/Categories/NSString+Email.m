//
//  NSString+Email.m
//  AFMailClient
//
//  Created by Andrey Yastrebov on 22.08.13.
//  Copyright (c) 2013 AgileFusion. All rights reserved.
//

#import "NSString+Email.h"
#import "NSString+Validation.h"

@implementation NSString (Email)

- (BOOL)isEmailValid
{
    NSString *regexPattern = @"^[-a-z0-9!#$%&'*+/=?^_`{|}~]+(?:\\.[-a-z0-9!#$%&'*+/=?^_`{|}~]+)*@(?:[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?\\.)*(?:aero|arpa|asia|biz|cat|com|coop|edu|gov|info|int|jobs|mil|mobi|museum|name|net|org|pro|tel|travel|[a-z][a-z])$";
    return [self isConformsRegex:regexPattern];
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
