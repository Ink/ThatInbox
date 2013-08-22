//
//  AppDelegate.m
//  ThatInbox
//
//  Created by Liyan David Chang on 8/1/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import "AppDelegate.h"

#import <INK/INK.h>

#include <MailCore/MailCore.h>
#import "ComposerViewController.h"
#import "MenuViewController.h"

#import "ATConnect.h"
#define kApptentiveAPIKey @"b16fd212f216d867b676cfe443bed0ded538f2487c43c477bcb2e1ddb5d8c7a5"

#import "INKWelcomeViewController.h"
#import "UTIFunctions.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    ATConnect *connection = [ATConnect sharedConnection];
    connection.apiKey = kApptentiveAPIKey;
    
    [Ink setupWithAppKey:@"AwCJXBinboxlxzkfuJyz"];
    [[INKCoreManager sharedManager] registerAdditionalURLScheme:@"thatinbox"];
    
    INKAction *reply = [INKAction action:@"Send Email with Attachment" type:INKActionType_Send];
    [Ink registerAction:reply withTarget:self selector:@selector(replyBlob:action:error:)];
    
    [UIBarButtonItem configureFlatButtonsWithColor:[UIColor cloudsColor]
                                  highlightedColor:[UIColor concreteColor]
                                      cornerRadius:3];
        
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *leftNavigationController = [splitViewController.viewControllers objectAtIndex:0];
    
    
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    splitViewController.delegate = (id)navigationController.topViewController;
    
    MenuViewController *listController = [[MenuViewController alloc] init];
    listController.delegate = (id)leftNavigationController.topViewController;
    
    NSDictionary *options = @{
                              PKRevealControllerAllowsOverdrawKey : [NSNumber numberWithBool:YES],
                              PKRevealControllerDisablesFrontViewInteractionKey : [NSNumber numberWithBool:NO],
                              PKRevealControllerRecognizesResetTapOnFrontViewKey : [NSNumber numberWithBool:NO],
                              PKRevealControllerRecognizesPanningOnFrontViewKey: [NSNumber numberWithBool:YES]
                              };

    
    self.revealController = [PKRevealController revealControllerWithFrontViewController:splitViewController
                                                                     leftViewController:listController
                                                                    rightViewController:nil
                                                                                options:options];

    
    if ([INKWelcomeViewController shouldRunWelcomeFlow]) {
        INKWelcomeViewController * welcomeViewController;
        welcomeViewController = [[INKWelcomeViewController alloc] initWithNibName:@"INKWelcomeViewController" bundle:nil];
        
        welcomeViewController.nextViewController = self.revealController;;
        [self.window setRootViewController:welcomeViewController];
    } else {
        [self.window setRootViewController:self.revealController];
    }

    [[UILabel appearance] setFont:[UIFont fontWithName:@"HelveticaNeue" size:16.0]];

    return YES;
}

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    NSLog(@"URL: %@", url);
    if ([Ink openURL:url sourceApplication:sourceApplication annotation:annotation]){
        NSLog(@"Can handle open url");
        return YES;
    }
    NSLog(@"Cannot handle open url");
    return NO;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void) replyBlob:(INKBlob *)blob action:(INKAction*)action error:(NSError*)error
{

    MCOAttachment *attachment = [[MCOAttachment alloc] init];
    [attachment setData:[blob data]];
    [attachment setMimeType:[UTIFunctions mimetypeFromUTI:[blob uti]]];
    [attachment setFilename:[UTIFunctions filenameFromFilename:[blob filename] UTI:[blob uti]]];
        
    ComposerViewController *vc = [[ComposerViewController alloc] initWithTo:@[] CC:@[] BCC:@[] subject:@"" message:@"" attachments:@[attachment] delayedAttachments:@[]];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    nc.modalPresentationStyle = UIModalPresentationPageSheet;
    
    UIViewController *root = [[[[UIApplication sharedApplication]delegate] window] rootViewController];
    [root presentViewController:nc animated:YES completion:nil];
}


@end
