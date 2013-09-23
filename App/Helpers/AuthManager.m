//
//  AuthManager.m
//  ThatInbox
//
//  Created by Liyan David Chang on 7/31/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import "AuthManager.h"
#import "AuthNavigationViewController.h"
#import <GContacts/GDataContacts.h>

/***********************************************************************

 You'll need a Gmail Client ID and Secret. Takes about 5 minutes.

 1. Go to the Google API Console:
 code.google.com/apis/console

 2. After logging in, you'll need to create a project.
 
 If this is your first project, it'll be a central button.
 Otherwise, it'll be the the menu on the left hand side.
 
 3. Configure it.
 
 - You won't been to select any services when asked.
 - Select "API Access" on the left hand menu.
   - Create an OAuth 2.0 client ID
   - Fill out the form. You can get the icon from ThatInbox/Graphics/AppIcons/icon.png
   - On the next page, you'll select "Installed application"
   - Select iOS. You'll need to specify the bundle id. Use the bundle id, which is set to com.inkmobility.thatinbox.
   - The App Store ID ad Deep Linking are optional and you should leave them blank.
 
 4. Copy your Client ID and Client Secret below

 5. Remove the #error line to proceed.

 ************************************************************************/

#error Just one thing before you get started. You'll need to configure the OAuth to communicate with Gmail. It takes about 5 minutes and the instructions are above.

#define CLIENT_ID @"XXXXXXXXXXXXX.apps.googleusercontent.com"
#define CLIENT_SECRET @"XXXXXXXXXXXXXXXXXXXXXXXX"
#define KEYCHAIN_ITEM_NAME @"Mailer OAuth 2.0 Token"

NSString * const HostnameKey = @"hostname";
NSString * const SmtpHostnameKey = @"smtphostname";

@interface AuthManager () <AuthViewControllerDelegate>

@property (nonatomic, strong) MCOIMAPSession *imapSession;
@property (nonatomic, strong) MCOSMTPSession *smtpSession;
@property (nonatomic, strong) GTMOAuth2Authentication* auth;
@property (nonatomic, strong, readwrite) GDataFeedContact *googleContacts;

@end

@implementation AuthManager

+ (id)sharedManager
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
        
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{ HostnameKey: @"imap.gmail.com" }];
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{ SmtpHostnameKey: @"smtp.gmail.com" }];
        
        [_sharedObject refresh];
    });
    return _sharedObject;
}

- (void) refresh
{
    GTMOAuth2Authentication * auth = [AuthViewController authForGoogleFromKeychainForName:KEYCHAIN_ITEM_NAME
                                                                                 clientID:CLIENT_ID
                                                                             clientSecret:CLIENT_SECRET];
    if ([auth refreshToken] == nil)
    {
        AuthNavigationViewController *authViewController = [AuthNavigationViewController controllerWithTitle:@"ThatInbox authentication"
                                                                                                       scope:@"https://mail.google.com/ https://www.google.com/m8/feeds"
                                                                                                    clientID:CLIENT_ID
                                                                                                clientSecret:CLIENT_SECRET
                                                                                            keychainItemName:KEYCHAIN_ITEM_NAME];
        authViewController.dismissOnSuccess = YES;
        authViewController.dismissOnError = YES;
        
        authViewController.delegate = self;
        
        [authViewController presentFromRootAnimated:YES completion:nil];
    }
    else
    {
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
    [self requestGoogleContacts:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Finished_OAuth" object:nil];
}

- (void)logout
{
    [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:KEYCHAIN_ITEM_NAME];
    [GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:self.auth];
    self.auth = nil;
    self.imapSession = nil;
    self.smtpSession = nil;
    
    NSLog(@"logout");
}

#pragma mark - Mail Services

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

#pragma mark - Contacts Services

- (void) requestGoogleContacts:(void (^)(GDataFeedContact *feed, NSError *error))handler
{
    if (!self.googleContacts)
    {
        if (!self.auth)
        {
            if (handler)
            {
                handler(nil, nil);
            }
        }
        
        GDataServiceGoogleContact *service = [self contactService];
        GDataServiceTicket *ticket;
        
        NSURL *feedURL = [GDataServiceGoogleContact contactFeedURLForUserID:kGDataServiceDefaultUser
                                                                 projection:kGDataGoogleContactFullProjection];
        
        GDataQueryContact *query = [GDataQueryContact contactQueryWithFeedURL:feedURL];
        [query setShouldShowDeleted:NO];
        [query setMaxResults:2000];
        
        ticket = [service fetchFeedWithQuery:query
                           completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error)
                  {
                      if (!error)
                      {
                          self.googleContacts = (GDataFeedContact *)feed;
                      }
                      
                      if (handler)
                      {
                          handler((GDataFeedContact *)feed, error);
                      }
                  }];
        
    }
    
    if (handler)
    {
        handler(self.googleContacts, nil);
    }
}

- (GDataServiceGoogleContact *)contactService
{
    static GDataServiceGoogleContact* service = nil;
    
    if (!service)
    {
        service = [[GDataServiceGoogleContact alloc] init];
        
        [service setShouldCacheResponseData:YES];
        [service setServiceShouldFollowNextLinks:YES];
    }
    
    [service setAuthorizer:self.auth];
    
    return service;
}

#pragma mark - AuthViewControllerDelegate

- (void)authViewController:(AuthViewController *)controller didRetrievedAuth:(GTMOAuth2Authentication *)retrievedAuth
{
    [self finishedAuth:retrievedAuth];
}

- (void)authViewController:(AuthViewController *)controller didFailedWithError:(NSError *)error
{
    // TODO: Handle error
    NSLog(@"error occurred: %@", error.localizedDescription);
}

@end
