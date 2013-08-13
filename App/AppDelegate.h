//
//  AppDelegate.h
//  iOS UI Test
//
//  Created by Jonathan Willing on 4/8/13.
//  Copyright (c) 2013 AppJon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PKRevealController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong, readwrite) PKRevealController *revealController;
@property (strong, nonatomic) UIWindow *window;

@end
