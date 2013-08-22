//
//  FPMimetype.h
//  Bin
//
//  Created by Liyan David Chang on 7/28/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FPMimetype : NSObject

+ (NSString*) iconPathForMimetype: (NSString *)mimetype Filename: (NSString *) filename;
+ (NSString*) iconPathForMimetype: (NSString *)mimetype;
+ (NSString*) iconPathForFilename: (NSString *)filename;

@end
