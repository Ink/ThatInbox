//
//  main.m
//  ThatInbox
//
//  Created by Liyan David Chang on 8/3/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"
#import <MailCore/MailCore.h>

int main(int argc, char *argv[])
{
    @autoreleasepool {
        MCLogEnabled = 0;
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}