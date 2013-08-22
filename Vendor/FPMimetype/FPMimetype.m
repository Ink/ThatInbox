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
static NSDictionary *specific_extension = nil;

static NSString *fallback = @"page_white.png";

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
    
    if (!specific_extension){
        specific_extension = @{
                               @"png": @"page_white_picture.png",
                               @"jpeg": @"page_white_picture.png",
                               @"jpg": @"page_white_picture.png",
                               @"gif": @"page_white_picture.png",
                               @"tiff": @"page_white_picture.png",
                               @"bmp": @"page_white_picture.png",

                               @"txt":@"page_white_text.png",
                               @"text":@"page_white_text.png",
                               @"rtf":@"page_white_text.png",

                               @"mp3":@"page_white_sound.png",
                               @"flac":@"page_white_sound.png",
                               @"aac":@"page_white_sound.png",
                               @"ogg":@"page_white_sound.png",
                               @"m4a":@"page_white_sound.png",
                               @"wma":@"page_white_sound.png",
                               @"wav":@"page_white_sound.png",

                               @"avi":@"page_white_film.png",
                               @"m4v":@"page_white_film.png",
                               @"mov":@"page_white_film.png",
                               @"mp4":@"page_white_film.png",
                               @"wmv":@"page_white_film.png",
                               
                               @"pdf": @"page_white_acrobat.png",
                               
                               @"key": @"keynote.png",
                               @"pages": @"pages.png",
                               @"numbers": @"numbers.png",
                               
                               @"zip": @"page_white_compressed.png",
                               @"tar": @"page_white_compressed.png",
                               @"gzip": @"page_white_compressed.png",
                               
                               @"xls": @"page_white_excel.png",
                               @"xlsx": @"page_white_excel.png",
                               
                               @"doc": @"page_white_word.png",
                               @"docx": @"page_white_word.png",
                               
                               @"ppt": @"page_white_powerpoint.png",
                               @"pptx": @"page_white_powerpoint.png",                               
                               
                               @"psd": @"page_white_paint.png",
                               
                               @"ai": @"page_white_vector.png",
                               
                               @"rb": @"page_white_ruby.png",
                               @"erb": @"page_white_ruby.png",
                               
                               @"php": @"page_white_php.png",
                               
                               @"js": @"page_white_js.png",
                               @"json": @"page_white_js.png",
                               
                               @"c": @"page_white_c@2x.png",
                               @"cpp": @"page_white_c@2x.png",

                               @"java": @"page_white_cup.png",
                               
                               @"flv": @"page_white_flash.png",
                               
                               @"dmg": @"page_white_dvd.png"
                               };
    }
}

+ (NSString*) iconPathForMimetype: (NSString *)mimetype Filename: (NSString *) filename {
    NSString *iconPath = [FPMimetype iconPathForMimetype:mimetype];
    if ([iconPath isEqualToString:fallback]){
        //return something else based on filename
        return [FPMimetype iconPathForFilename:filename];
    } else {
        return iconPath;
    }
}

+ (NSString*) iconPathForFilename: (NSString *)filename {
    NSString *extension = [filename pathExtension];
    NSString *iconPath = [specific_extension objectForKey:extension];
    if (iconPath){
        return iconPath;
    } else {
        return fallback;
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
    return fallback;
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
