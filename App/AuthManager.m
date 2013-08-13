//
//  AuthManager.m
//  Mailer
//
//  Created by Liyan David Chang on 7/31/13.
//  Copyright (c) 2013 com.inkmobility. All rights reserved.
//

#import "AuthManager.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "SettingsViewController.h"

#define CLIENT_ID @"1078833445713.apps.googleusercontent.com"
#define CLIENT_SECRET @"lTaX8Z2vVssDHaVbQ9cGJsXk"
#define KEYCHAIN_ITEM_NAME @"Mailer OAuth 2.0 Token"


@interface AuthManager ()

@property (nonatomic, strong) MCOIMAPSession *imapSession;
@property (nonatomic, strong) MCOSMTPSession *smtpSession;
@property (nonatomic, strong) GTMOAuth2Authentication* auth;

@end

@implementation AuthManager

+ (id)sharedManager {
    static AuthManager *sharedMyManager = nil;
    
    @synchronized(self) {
        if (!sharedMyManager){
            sharedMyManager = [[self alloc] init];
            
            [[NSUserDefaults standardUserDefaults] registerDefaults:@{ HostnameKey: @"imap.gmail.com" }];
            [[NSUserDefaults standardUserDefaults] registerDefaults:@{ SmtpHostnameKey: @"smtp.gmail.com" }];
            
            [sharedMyManager refresh];
        }
    }
    return sharedMyManager;
}

- (void) refresh
{
    GTMOAuth2Authentication * auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:KEYCHAIN_ITEM_NAME
                                                                                           clientID:CLIENT_ID
                                                                                       clientSecret:CLIENT_SECRET];
    
    if ([auth refreshToken] == nil) {
        AuthManager * __weak weakSelf = self;
        GTMOAuth2ViewControllerTouch *viewController = [GTMOAuth2ViewControllerTouch controllerWithScope:@"https://mail.google.com/"
                                                                                                clientID:CLIENT_ID
                                                                                            clientSecret:CLIENT_SECRET
                                                                                        keychainItemName:KEYCHAIN_ITEM_NAME
                                                                                       completionHandler:^(GTMOAuth2ViewControllerTouch *viewController, GTMOAuth2Authentication *retrievedAuth, NSError *error) {
                                                                                           [weakSelf finishedFirstAuth:retrievedAuth];
                                                                                           [viewController dismissViewControllerAnimated:NO completion:nil];
                                                                                    }];
        UIViewController *root = [[[[UIApplication sharedApplication]delegate] window] rootViewController];
        [root presentViewController:viewController animated:YES completion:nil];
    }
    else {
        [auth beginTokenFetchWithDelegate:self
                        didFinishSelector:@selector(auth:finishedRefreshWithFetcher:error:)];
    }
}


- (void)auth:(GTMOAuth2Authentication *)auth
finishedRefreshWithFetcher:(GTMHTTPFetcher *)fetcher
       error:(NSError *)error {
    [self finishedAuth:auth];
}

- (void)finishedFirstAuth:(GTMOAuth2Authentication*)auth {
    self.auth = auth;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Finished_FirstOAuth" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Finished_OAuth" object:nil];
}

- (void)finishedAuth:(GTMOAuth2Authentication*)auth {
    self.auth = auth;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Finished_OAuth" object:nil];
}


- (MCOSMTPSession *) getSmtpSession {
    if (!self.smtpSession){
        if (!self.auth){
            return nil;
        }
        
        MCOSMTPSession* smtpSession = [[MCOSMTPSession alloc] init];
        NSString *smtphostname = [[NSUserDefaults standardUserDefaults] objectForKey:SmtpHostnameKey];
        smtpSession.hostname = smtphostname;
        smtpSession.port = 465;
        smtpSession.connectionType = MCOConnectionTypeTLS;
        
        smtpSession.authType = MCOAuthTypeXOAuth2;
        smtpSession.OAuth2Token = [self.auth accessToken];
        smtpSession.username = [self.auth userEmail];
        smtpSession.password = @"";
        self.smtpSession = smtpSession;
    }
    return self.smtpSession;
}

- (MCOIMAPSession *) getImapSession {
    if (!self.imapSession){
        if (!self.auth){
            return nil;
        }

        NSString *hostname = [[NSUserDefaults standardUserDefaults] objectForKey:HostnameKey];

        MCOIMAPSession *imapSession = [[MCOIMAPSession alloc] init];
        imapSession.hostname = hostname;
        imapSession.port = 993;
        imapSession.username = [self.auth userEmail];
        imapSession.password = @"";
        imapSession.OAuth2Token = [self.auth accessToken];
        imapSession.authType = MCOAuthTypeXOAuth2;
        imapSession.connectionType = MCOConnectionTypeTLS;
        self.imapSession = imapSession;
    }
    return self.imapSession;
}

- (void)logout {
    [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:KEYCHAIN_ITEM_NAME];
    [GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:self.auth];
    self.auth = nil;
    self.imapSession = nil;
    self.smtpSession = nil;
    
    NSLog(@"logout");
    
}

@end
