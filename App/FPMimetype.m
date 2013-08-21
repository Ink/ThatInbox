//
//  FPMimetype.m
//  Bin
//
//  Created by Liyan David Chang on 7/28/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import "FPMimetype.h"

static NSDictionary *specific_mimetype = nil;
static NSDictionary *general_mimetype = nil;

@implementation FPMimetype

+ (void) initialize {
    if (!specific_mimetype){
        specific_mimetype = @{
            @"adobe/pdf": @"page_white_acrobat.png",
            @"application/pdf": @"page_white_acrobat.png",

            
            @"application/x-iwork-keynote-sffkey": @"keynote.png",
            @"application/x-iwork-pages-sffpages": @"pages.png",
            @"application/x-iwork-numbers-sffnumbers": @"numbers.png",
            @"application/pgp-keys": @"keynote.png",
            
            @"application/x-cpio": @"page_white_compressed.png",
            @"application/x-shar": @"page_white_compressed.png",
            @"application/x-tar": @"page_white_compressed.png",
            @"application/x-gzip": @"page_white_compressed.png",
            @"application/x-bzip2": @"page_white_compressed.png",
            @"application/x-rar-compressed":@"page_white_compressed.png",
            @"application/x-gtar":@"page_white_compressed.png",
            @"application/zip":@"page_white_compressed.png",

            @"application/vnd.ms-excel": @"page_white_excel.png",
            @"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": @"page_white_excel.png",
            @"application/vnd.openxmlformats-officedocument.spreadsheetml.template": @"page_white_excel.png",
            @"application/vnd.ms-excel.sheet.macroEnabled.12": @"page_white_excel.png",
            @"application/vnd.ms-excel.template.macroEnabled.12": @"page_white_excel.png",
            @"application/vnd.ms-excel.addin.macroEnabled.12": @"page_white_excel.png",
            @"application/vnd.ms-excel.sheet.binary.macroEnabled.12": @"page_white_excel.png",

            @"application/msword": @"page_white_word.png",
            @"application/vnd.openxmlformats-officedocument.wordprocessingml.document": @"page_white_word.png",
            @"application/vnd.openxmlformats-officedocument.wordprocessingml.template": @"page_white_word.png",
            @"application/vnd.ms-word.document.macroEnabled.12": @"page_white_word.png",
            @"application/vnd.ms-word.template.macroEnabled.12": @"page_white_word.png",
            

            @"application/vnd.ms-powerpoint": @"page_white_powerpoint.png",
            @"application/vnd.openxmlformats-officedocument.presentationml.presentation": @"page_white_powerpoint.png",
            @"application/vnd.openxmlformats-officedocument.presentationml.template": @"page_white_powerpoint.png",
            @"application/vnd.openxmlformats-officedocument.presentationml.slideshow": @"page_white_powerpoint.png",
            @"application/vnd.ms-powerpoint.addin.macroEnabled.12": @"page_white_powerpoint.png",
            @"application/vnd.ms-powerpoint.presentation.macroEnabled.12": @"page_white_powerpoint.png",
            @"application/vnd.ms-powerpoint.template.macroEnabled.12": @"page_white_powerpoint.png",
            @"application/vnd.ms-powerpoint.slideshow.macroEnabled.12": @"page_white_powerpoint.png",
            
            
            @"image/photoshop": @"page_white_paint.png",
            @"image/x-photoshop": @"page_white_paint.png",
            @"image/psd": @"page_white_paint.png",
            @"application/photoshop": @"page_white_paint.png",
            @"application/psd": @"page_white_paint.png",
            
            @"application/illustrator": @"page_white_vector.png",
            
            @"application/x-httpd-eruby": @"page_white_ruby.png",
            @"application/x-httpd-eruby": @"page_white_ruby.png",
            @"text/x-ruby-script": @"page_white_ruby.png",

            @"text/php": @"page_white_php.png",
            
            @"application/javascript": @"page_white_js.png",
            @"text/javascript": @"page_white_js.png",
            @"application/json": @"page_white_code.png",
            
            @"text/x-c": @"page_white_c@2x.png",
            @"text/x-java-source": @"page_white_cup.png",
            
            @"video/flv": @"page_white_flash.png",
            @"video/x-flv": @"page_white_flash.png",
            
            @"application/x-apple-diskimage": @"page_white_dvd.png"
            };
    }
    
    if (!general_mimetype){
        general_mimetype = @{
            @"image/*": @"page_white_picture.png",
            @"text/*":@"page_white_text.png",
            @"audio/*":@"page_white_sound.png",
            @"video/*":@"page_white_film.png"
            };
    }
}

+ (NSString*) iconPathForMimetype: (NSString *)mimetype {
    mimetype = [mimetype lowercaseString];
    NSString *specific = [specific_mimetype objectForKey:mimetype];
    if (specific){
        return specific;
    }
    
    NSString *general = [general_mimetype objectForKey:[self generalMimetypeFromMimetype:mimetype]];
    if (general){
        return general;
    }
    
    //Fallback
    return @"page_white.png";
}

+ (NSString *) generalMimetypeFromMimetype: (NSString *)mimetype {
    
    @try {
        NSMutableArray *splitMimetype = [NSMutableArray arrayWithArray:[mimetype componentsSeparatedByString:@"/"]];
        [splitMimetype setObject:@"*" atIndexedSubscript:1];
        return [splitMimetype componentsJoinedByString:@"/"];
    }
    @catch (NSException *exception) {
        NSLog(@"Bad mimetype to generalize: %@", mimetype);
        return @"*/*";
    }
}

@end
