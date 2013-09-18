//
//  AuthViewController.h
//  ThatInbox
//
//  Created by Andrey Yastrebov on 11.09.13.
//  Copyright (c) 2013 com.inkmobility. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AuthViewController.h"

@class AuthNavigationViewController;

typedef void (^AuthViewControllerCompletionHandler)(AuthNavigationViewController *viewController, GTMOAuth2Authentication *auth, NSError *error);
typedef void (^AuthViewControllerDismissHandler)(BOOL dismissed);

@protocol AuthViewControllerDelegate <UINavigationControllerDelegate>
@optional
- (void)authViewController:(AuthNavigationViewController *)controller didRetrievedAuth:(GTMOAuth2Authentication *)retrievedAuth;
- (void)authViewController:(AuthNavigationViewController *)controller didFailedWithError:(NSError *)error;
@end

@interface AuthNavigationViewController : UINavigationController
@property (nonatomic, weak) id<AuthViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL dismissOnSuccess; //Default is NO
@property (nonatomic, assign) BOOL dismissOnError; //Default is NO

+ (id)controllerWithTitle:(NSString *)title
                    scope:(NSString *)scope
                 clientID:(NSString *)clientID
             clientSecret:(NSString *)clientSecret
         keychainItemName:(NSString *)keychainItemName;

- (id)initWithTitle:(NSString *)title
              scope:(NSString *)scope
           clientID:(NSString *)clientID
       clientSecret:(NSString *)clientSecret
   keychainItemName:(NSString *)keychainItemName;

+ (GTMOAuth2Authentication *)authForGoogleFromKeychainForName:(NSString *)keychainItemName
                                                     clientID:(NSString *)clientID
                                                 clientSecret:(NSString *)clientSecret;

- (void)setCompletionHandler:(AuthViewControllerCompletionHandler)handler;
- (void)setDismissHandler:(AuthViewControllerDismissHandler)handler;


- (void)presentFromRootAnimated:(BOOL)flag completion:(void (^)(void))completion;

@end

