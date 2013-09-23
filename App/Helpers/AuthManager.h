//
//  AuthManager.h
//  ThatInbox
//
//  Created by Liyan David Chang on 7/31/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>

extern NSString * const HostnameKey;
extern NSString * const SmtpHostnameKey;

@class GDataFeedContact;

@interface AuthManager : NSObject

@property (nonatomic, strong, readonly) GDataFeedContact *googleContacts;

+ (id)sharedManager;

- (void)refresh;
- (void)logout;

- (MCOSMTPSession *) getSmtpSession;
- (MCOIMAPSession *) getImapSession;

- (void) requestGoogleContacts:(void (^)(GDataFeedContact *feed, NSError *error))handler;

@end
