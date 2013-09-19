//
//  NSString+Email.h
//  AFMailClient
//
//  Created by Andrey Yastrebov on 22.08.13.
//  Copyright (c) 2013 AgileFusion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Email)
- (BOOL)isEmailValid;
- (NSString *)emailDomain;
- (NSString *)emailDomainUpperCase;
@end
