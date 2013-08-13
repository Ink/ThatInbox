//
//  MasterViewController.h
//  iOS UI Test
//
//  Created by Jonathan Willing on 4/8/13.
//  Copyright (c) 2013 AppJon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MessageDetailViewController.h"
#import "MessageListDelegate.h"
#import "ListViewController.h"

@interface MasterViewController : UITableViewController <MessageListDelegate, ListViewDelegate>

- (IBAction)showLeftView:(id)sender;
- (IBAction)composeEmail:(id)sender;
@property (strong, nonatomic) MessageDetailViewController *detailViewController;
@property (strong) NSString *folder;
@property (strong) NSString *folderParent;


@end
