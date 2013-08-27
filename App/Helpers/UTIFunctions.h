//
//  UTIFunctions.h
//  ThatInbox
//
//  Created by Liyan David Chang on 8/21/13.
//  Copyright (c) 2013 com.inkmobility. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UTIFunctions : NSObject

+ (NSString *)filenameFromFilename:(NSString*)filename UTI:(NSString*)uti;
+ (NSString *) mimetypeFromUTI:(NSString*)uti;
+ (NSString *) UTIFromMimetype:(NSString *)mimetype Filename: (NSString *)filename;
+ (NSString *) UTIFromMimetype: (NSString*)mimetype;
+ (NSString *) UTIFromFilename: (NSString*)filename;

@end
