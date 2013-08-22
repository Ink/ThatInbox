//
//  MsgListViewController.h
//  ThatInbox
//
//  Created by Liyan David Chang on 8/1/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MessageDetailViewController.h"
#import "MessageListDelegate.h"
#import "MenuViewController.h"

@interface MsgListViewController : UITableViewController <MessageListDelegate, MenuViewDelegate>

@property (strong, nonatomic) MessageDetailViewController *detailViewController;
@property (strong) NSString *folder;
@property (strong) NSString *folderParent;

- (IBAction)showLeftView:(id)sender;
- (IBAction)composeEmail:(id)sender;

@end
