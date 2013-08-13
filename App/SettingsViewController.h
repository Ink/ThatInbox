//
//  SettingsViewController.h
//  iOS UI Test
//
//  Created by Jonathan Willing on 4/8/13.
//  Copyright (c) 2013 AppJon. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const HostnameKey;
extern NSString * const SmtpHostnameKey;

@protocol SettingsViewControllerDelegate;

@interface SettingsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextView *signature;

- (IBAction)logout:(id)sender;


@property (nonatomic, weak) id<SettingsViewControllerDelegate> delegate;
- (IBAction)done:(id)sender;

@end

@protocol SettingsViewControllerDelegate <NSObject>
- (void)settingsViewControllerFinished:(SettingsViewController *)viewController;
@end