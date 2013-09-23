//
//  AuthViewController.m
//  ThatInbox
//
//  Created by Andrey Yastrebov on 18.09.13.
//  Copyright (c) 2013 com.inkmobility. All rights reserved.
//

#import "AuthViewController.h"
#import "UIColor+FlatUI.h"

@interface AuthViewController ()
- (void)hideBackButton:(BOOL)hide;
@end

@implementation AuthViewController

- (void)hideBackButton:(BOOL)hide
{    
    if (hide)
    {
        self.navigationItem.leftBarButtonItem = nil;
    }
    else
    {
        UIBarButtonItem *bb = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:self.webView action:@selector(goBack)];
        
        [bb setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"HelveticaNeue" size:16.0], UITextAttributeFont, [UIColor peterRiverColor], UITextAttributeTextColor, [UIColor clearColor], UITextAttributeTextShadowColor, nil] forState:UIControlStateNormal];
        [bb setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"HelveticaNeue" size:16.0], UITextAttributeFont, [UIColor belizeHoleColor], UITextAttributeTextColor, nil] forState:UIControlStateHighlighted];
        [bb setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"HelveticaNeue" size:16.0], UITextAttributeFont, [UIColor lightGrayColor], UITextAttributeTextColor, [UIColor clearColor], UITextAttributeTextShadowColor, nil] forState:UIControlStateDisabled];
        
        
        self.navigationItem.leftBarButtonItem = bb;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = nil;
    
    // Optional: display some html briefly before the sign-in page loads
    NSString *html = @"<html><body bgcolor=silver><div align=center>Loading sign-in page...</div></body></html>";
    self.initialHTMLString = html;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self hideBackButton:![webView canGoBack]];
    [super webViewDidFinishLoad:webView];
}

@end
