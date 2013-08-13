//
//  AuthManager.h
//  Mailer
//
//  Created by Liyan David Chang on 7/31/13.
//  Copyright (c) 2013 com.inkmobility. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>

@interface AuthManager : NSObject

+ (id)sharedManager;
- (void)refresh;
- (void)logout;

- (MCOSMTPSession *) getSmtpSession;
- (MCOIMAPSession *) getImapSession;

@end
