//
//  MessageDetailViewController.m
//  iOS UI Test
//
//  Created by Liyan David Chang on 7/9/13.
//  Copyright (c) 2013 AppJon. All rights reserved.
//

#import "MessageDetailViewController.h"

#import "UINavigationBar+FlatUI.h"
#import "ComposerViewController.h"
#import "UIColor+FlatUI.h"

#import "DelayedAttachment.h"


@interface MessageDetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;

@end

@implementation MessageDetailViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.navigationController.navigationBar configureFlatNavigationBarWithColor:[UIColor cloudsColor]];
    
    if (self.message != nil){
        UIBarButtonItem *archiveButton = [[UIBarButtonItem alloc] initWithTitle:@"Archive"
                                                                          style:UIBarButtonItemStyleDone target:self action:@selector(archiveMessage:)];

        UIBarButtonItem *replyButton = [[UIBarButtonItem alloc] initWithTitle:@"Reply"
                                                                        style:UIBarButtonItemStyleDone target:self action:@selector(replyWindow:)];
        UIBarButtonItem *replyAllButton = [[UIBarButtonItem alloc] initWithTitle:@"Reply All"
                                                                        style:UIBarButtonItemStyleDone target:self action:@selector(replyWindow:)];
        UIBarButtonItem *forwardButton = [[UIBarButtonItem alloc] initWithTitle:@"Forward"
                                                                        style:UIBarButtonItemStyleDone target:self action:@selector(replyWindow:)];
        
        for (UIBarButtonItem *bb in @[archiveButton, replyButton, replyAllButton, forwardButton]){
            [bb setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"HelveticaNeue" size:16.0], UITextAttributeFont, [UIColor peterRiverColor], UITextAttributeTextColor, [UIColor clearColor], UITextAttributeTextShadowColor, nil] forState:UIControlStateNormal];
            [bb setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"HelveticaNeue" size:16.0], UITextAttributeFont, [UIColor belizeHoleColor], UITextAttributeTextColor, nil] forState:UIControlStateHighlighted];
        }
        
        if ([self.folder isEqualToString:@"INBOX"]){
            self.navigationItem.leftBarButtonItems = @[archiveButton];
        } else {
            self.navigationItem.leftBarButtonItems = @[];
        }
        self.navigationItem.rightBarButtonItems = @[forwardButton, replyAllButton, replyButton];
    } else {
        self.navigationItem.leftBarButtonItems = @[];
        self.navigationItem.rightBarButtonItems = @[];
        self.view = [[UIView alloc] initWithFrame:self.view.frame];
        self.view.backgroundColor = [UIColor whiteColor];
    }
    
    //Hide master if selected and in portait master detail
    //But show if no message
    if (self.masterPopoverController != nil && self.message != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    } else {
        [self.masterPopoverController presentPopoverFromBarButtonItem:nil permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)replyWindow:(id)sender{
    
    NSString *type = [((UIBarButtonItem*) sender) title];
    NSMutableArray *delayedAttachments = [[NSMutableArray alloc] init];
    
    if ([type isEqualToString: @"Forward"]){
        // It would be nice to forward, but we can't because these are MCOIMAPParts, not MCOAttachments bc we don't have the data yet.
        //attachments = [self.message attachments];
        for (MCOIMAPPart *a in [self.message attachments]) {
            DelayedAttachment *da = [[DelayedAttachment alloc] initWithMCOIMAPPart:a];
            da.fetchData = ^(void){
                __block NSData *data = [self MCOMessageView:_messageView dataForPartWithUniqueID:[a uniqueID]];
                if (data){
                    return data;
                } else {
                    __block NSConditionLock* fetchLock;
                    fetchLock = [[NSConditionLock alloc] initWithCondition:1];
                    
                    [self MCOMessageView:_messageView fetchDataForPartWithUniqueID:[a uniqueID] downloadedFinished:^(NSError * error) {
                        data = [self MCOMessageView:_messageView dataForPartWithUniqueID:[a uniqueID]];
                        [fetchLock lock];
                        [fetchLock unlockWithCondition:0];
                    }];
                    
                    [fetchLock lockWhenCondition:0];
                    [fetchLock unlock];
                    return data;
                }                
                //return [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://ws.cdyne.com/WeatherWS/Images/thunderstorms.gif"]];
            };
            [delayedAttachments addObject:da];
        }
    }

    ComposerViewController *vc = [[ComposerViewController alloc] initWithMessage:[self message] ofType:type content:[self msgContent] attachments:@[] delayedAttachments:delayedAttachments];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    nc.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:nc animated:YES completion:nil];
}

- (IBAction)archiveMessage:(id)sender {
    [[self delegate] archiveMessage:[[self message] uid]];
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    //NOTE: This isn't used given that we no longer hide. See comment in splitViewController:shouldHideViewController:...
    barButtonItem.title = @"Messages";
    
    [barButtonItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"HelveticaNeue" size:16.0], UITextAttributeFont, [UIColor peterRiverColor], UITextAttributeTextColor, [UIColor clearColor], UITextAttributeTextShadowColor, nil] forState:UIControlStateNormal];
    [barButtonItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"HelveticaNeue" size:16.0], UITextAttributeFont, [UIColor belizeHoleColor], UITextAttributeTextColor, nil] forState:UIControlStateHighlighted];

    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation {
    //NOTE: You'll want this. Otherwise, if you hide the controller, then you get into two problems:
    // 1. The slide gestures collide.
    // 2. The popoverController will be fixed to the left side, just like your menu, and in fact will hide the menu.
    // Therefore, we are going with the reasonable approach of just not hiding ever, and just making the email side smaller.
    return NO;
}

@end
