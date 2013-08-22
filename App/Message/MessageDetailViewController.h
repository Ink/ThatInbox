//
//  MessageDetailViewController.h
//  ThatInbox
//
//  Created by Liyan David Chang on 7/9/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCTMsgViewController.h"
#import "MessageListDelegate.h"

@interface MessageDetailViewController : MCTMsgViewController <UISplitViewControllerDelegate>

@property (nonatomic, assign) id<MessageListDelegate> delegate;

@end
