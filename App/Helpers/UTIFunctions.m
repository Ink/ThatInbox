//
//  UTIFunctions.m
//  ThatInbox
//
//  Created by Liyan David Chang on 8/21/13.
//  Copyright (c) 2013 com.inkmobility. All rights reserved.
//

#import "UTIFunctions.h"

@implementation UTIFunctions

+ (NSString *)filenameFromFilename:(NSString*)filename UTI:(NSString*)uti {

    if (filename){
        return filename;
    }
    
    NSDate *currDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"dd.MM.YY HH:mm:ss"];
    NSString *dateString = [dateFormatter stringFromDate:currDate];
    NSString *extension = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)(uti), kUTTagClassFilenameExtension);
    if (!extension){
        extension = @"file";
    }
    return [NSString stringWithFormat:@"%@.%@", dateString, extension];
}

+ (NSString *) mimetypeFromUTI:(NSString*)uti {
    NSString *mimetype = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)uti, kUTTagClassMIMEType);
    return mimetype ? mimetype : @"application/octet-stream";
}

+ (NSString *) UTIFromMimetype: (NSString*)mimetype {
    return (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)mimetype, (__bridge CFStringRef)@"public.data");
}

@end
