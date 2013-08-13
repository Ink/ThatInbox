//
//  EmailParser.m
//  Mailer
//
//  Created by Liyan David Chang on 8/1/13.
//  Copyright (c) 2013 com.inkmobility. All rights reserved.
//

#import "EmailParser.h"

@implementation EmailParser

+ (NSArray *) parseMessage:(NSString *)message {
    
    NSArray *messageLines = [message componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray *primary = [[NSMutableArray alloc] init];
    NSMutableArray *secondary = [[NSMutableArray alloc] init];

    NSMutableArray *buffer = [[NSMutableArray alloc] init];
    
    BOOL reply = NO;
    
    int on_triggered = 0;
    
    
    for (NSString* line in messageLines){
        if (reply == NO){
            if (on_triggered > 0|| [line rangeOfString:@"On "].location != NSNotFound){
                
                on_triggered = (on_triggered +1)%3;
                
                if ([line rangeOfString:@" wrote:"].location != NSNotFound){
                    reply = YES;
                    on_triggered = 0;
                    [secondary addObjectsFromArray:buffer];
                    [buffer removeAllObjects];
                }
            }
        }
        
        if (on_triggered > 0){
            [buffer addObject:line];
        } else if (reply == NO){
            [primary addObject:line];
        } else {
            [secondary addObject:line];
        }
    }

    return @[[primary componentsJoinedByString:@"\n"], [secondary componentsJoinedByString:@"\n"] ];
}

@end
