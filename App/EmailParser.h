//
//  EmailParser.h
//  Mailer
//
//  Created by Liyan David Chang on 8/1/13.
//  Copyright (c) 2013 com.inkmobility. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EmailParser : NSObject

+ (NSArray *) parseMessage:(NSString *)message;

@end
