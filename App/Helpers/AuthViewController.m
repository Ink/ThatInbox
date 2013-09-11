//
//  AuthViewController.m
//  ThatInbox
//
//  Created by Andrey Yastrebov on 11.09.13.
//  Copyright (c) 2013 com.inkmobility. All rights reserved.
//

#import "AuthViewController.h"

@interface AuthViewController ()
{
    AuthViewControllerCompletionHandler _completeHandler;
    AuthViewControllerDismissHandler _dismissHandler;
    
    UIActivityIndicatorView *_activityIndicator;
}
@end

@implementation AuthViewController

#pragma mark - Class methods

+ (GTMOAuth2Authentication *)authForGoogleFromKeychainForName:(NSString *)keychainItemName
                                                     clientID:(NSString *)clientID
                                                 clientSecret:(NSString *)clientSecret
{
    return [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:keychainItemName
                                                                 clientID:clientID
                                                             clientSecret:clientSecret];
}

+ (id)controllerWithTitle:(NSString *)title
                    scope:(NSString *)scope
                 clientID:(NSString *)clientID
             clientSecret:(NSString *)clientSecret
         keychainItemName:(NSString *)keychainItemName
{
    return [[self alloc] initWithTitle:title
                                 scope:scope
                              clientID:clientID
                          clientSecret:clientSecret
                      keychainItemName:keychainItemName];
}

#pragma mark - Init

- (id)initWithTitle:(NSString *)title
              scope:(NSString *)scope
           clientID:(NSString *)clientID
       clientSecret:(NSString *)clientSecret
   keychainItemName:(NSString *)keychainItemName
{
    GTMOAuth2ViewControllerTouch *viewController = [GTMOAuth2ViewControllerTouch controllerWithScope:scope
                                                                                            clientID:clientID
                                                                                        clientSecret:clientSecret
                                                                                    keychainItemName:keychainItemName
                                                                                            delegate:self
                                                                                    finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    viewController.title = title;
    
    self = [super initWithRootViewController:viewController];
    if (self)
    {
        _dismissOnSuccess = NO;
        _dismissOnError = NO;
        
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _activityIndicator.center = CGPointMake(_activityIndicator.frame.size.width, self.navigationBar.frame.size.height/2);
        _activityIndicator.hidden = YES;
        
        [self.navigationBar addSubview:_activityIndicator];
    }
    return self;
}

#pragma mark - Handler setters

- (void)setCompletionHandler:(AuthViewControllerCompletionHandler)handler
{
    _completeHandler = handler;
}

- (void)setDismissHandler:(AuthViewControllerDismissHandler)handler
{
    _dismissHandler = handler;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startedLoading:)
                                                 name:kGTMOAuth2WebViewStartedLoading
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stoppedLoading:)
                                                 name:kGTMOAuth2WebViewStoppedLoading
                                               object:nil];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Presention

- (void)presentFromRootAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    UIViewController *root = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [root presentViewController:self animated:flag completion:completion];
}

#pragma mark - Notifications

- (void)startedLoading:(id)sender
{
    if (_activityIndicator)
    {
        _activityIndicator.hidden = NO;
        [_activityIndicator startAnimating];
    }
}

- (void)stoppedLoading:(id)sender
{
    if (_activityIndicator)
    {
        _activityIndicator.hidden = YES;
        [_activityIndicator stopAnimating];
    }
}

#pragma mark - GTM Oauth Delegate

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error
{
    if (_completeHandler)
    {
        _completeHandler(self, auth, error);
    }
    
    if (error)
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(authViewController:didFailedWithError:)])
        {
            [self.delegate authViewController:self didFailedWithError:error];
        }
        
        if (self.dismissOnError)
        {
            [self dismissViewControllerAnimated:NO completion:^{
                if (_dismissHandler)
                {
                    _dismissHandler(YES);
                }
            }];
        }
    }
    
    if (auth)
    {        
        if (self.delegate && [self.delegate respondsToSelector:@selector(authViewController:didRetrievedAuth:)])
        {
            [self.delegate authViewController:self didRetrievedAuth:auth];
        }
        
        if (self.dismissOnSuccess)
        {
            [self dismissViewControllerAnimated:NO completion:^{
                if (_dismissHandler)
                {
                    _dismissHandler(YES);
                }
            }];
        }
    }
}

@end
