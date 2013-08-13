//
//  SettingsViewController.m
//  iOS UI Test
//
//  Created by Jonathan Willing on 4/8/13.
//  Copyright (c) 2013 AppJon. All rights reserved.
//

#import "SettingsViewController.h"
#import "FXKeychain.h"

#import "FlatUIKit.h"
#import "AuthManager.h"

NSString * const HostnameKey = @"hostname";
NSString * const SmtpHostnameKey = @"smtphostname";

@implementation SettingsViewController

- (void)done:(id)sender {
    
    [self.delegate settingsViewControllerFinished:self];
    NSLog(@"Saved Settings");
    //[self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.isMovingFromParentViewController || self.isBeingDismissed) {
        //Auto save whatever they put.
        [self done:self];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Settings";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController.navigationBar configureFlatNavigationBarWithColor:[UIColor cloudsColor]];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                   style:UIBarButtonItemStylePlain target:self action:@selector(done:)];
    [backButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"HelveticaNeue" size:16.0], UITextAttributeFont, [UIColor peterRiverColor], UITextAttributeTextColor, [UIColor clearColor], UITextAttributeTextShadowColor, nil] forState:UIControlStateNormal];

    self.navigationItem.leftBarButtonItem = backButton;
}

- (IBAction)logout:(id)sender {
    [[AuthManager sharedManager] logout];
}

@end
