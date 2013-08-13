//
//  DelayedAttachment.h
//  Mailer
//
//  Created by Liyan David Chang on 8/1/13.
//  Copyright (c) 2013 com.inkmobility. All rights reserved.
//

#import <MailCore/MailCore.h>

@interface DelayedAttachment : NSObject

@property (nonatomic, strong) NSData* (^fetchData)(void);
@property (nonatomic, strong) MCOIMAPPart* part;


@property (nonatomic, copy) NSString * filename;
@property (nonatomic, copy) NSString * mimeType;
@property (nonatomic, copy) NSString * uniqueID;



- (id) initWithMCOIMAPPart:(MCOIMAPPart *)part;

- (NSData*) getData;

@end
