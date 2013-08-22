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

+ (NSString *) UTIFromMimetype:(NSString *)mimetype Filename: (NSString *)filename {
    NSString *uti_m = [UTIFunctions UTIFromMimetype:mimetype];
    NSString *uti_f = [UTIFunctions UTIFromFilename:filename];
    
    if (UTTypeConformsTo((__bridge CFStringRef)(uti_f), (__bridge CFStringRef)(uti_m))){
        //uti_f is more specifc. use it
        return uti_f;
    }
    
    return uti_m;
}


+ (NSString *) UTIFromMimetype: (NSString*)mimetype {
    return (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)mimetype, (__bridge CFStringRef)@"public.data");
}

+ (NSString *) UTIFromFilename: (NSString*)filename {
    return (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[filename pathExtension], (__bridge CFStringRef)@"public.data");
}


@end
