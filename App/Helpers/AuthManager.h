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

@interface AuthManager : NSObject

+ (id)sharedManager;

- (void)refresh;
- (void)logout;

- (MCOSMTPSession *) getSmtpSession;
- (MCOIMAPSession *) getImapSession;

@end
