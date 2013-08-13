//
//  DelayedAttachment.m
//  Mailer
//
//  Created by Liyan David Chang on 8/1/13.
//  Copyright (c) 2013 com.inkmobility. All rights reserved.
//

#import "DelayedAttachment.h"

@interface DelayedAttachment ()

@property NSData *_data;

@end


@implementation DelayedAttachment

- (id) initWithMCOIMAPPart:(MCOIMAPPart *)part {
    
    //TODO: Hack. Not sure why I couldn't super class and init....
    if( (self = [super init]) ) {
        self.part = part;
        
        self.filename = part.filename;
        self.mimeType = part.mimeType;
        self.uniqueID = part.uniqueID;
    }
    return self;
}

- (NSData*) getData {
    if (self._data){
        return self._data;
    } else {
        self._data = self.fetchData();
        return self._data;
    }
}

@end
