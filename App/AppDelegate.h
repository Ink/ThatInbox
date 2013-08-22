//
//  AppDelegate.h
//  ThatInbox
//
//  Created by Liyan David Chang on 8/1/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PKRevealController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong, readwrite) PKRevealController *revealController;
@property (strong, nonatomic) UIWindow *window;

@end
